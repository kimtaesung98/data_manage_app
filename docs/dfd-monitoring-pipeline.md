# DFD — 노인 모니터링 브릿지 파이프라인

## 개요

BLE 웨어러블 기기로부터 심박수·활동 데이터를 수집하여 Firestore에 업로드하는 파이프라인.  
네트워크 단절 시 SQLite에 버퍼링하고, 재연결 시 자동 flush.

---

## 관련 파일

```
lib/
├── core/services/
│   ├── background_service.dart   ← 프로세스 생존 유지
│   └── network_monitor.dart      ← WiFi/LTE 감지
├── domain/
│   ├── entities/packet.dart      ← 데이터 구조 정의
│   └── repositories/
│       └── buffer_repository.dart ← 버퍼 추상 인터페이스
├── data/
│   ├── models/packet_model.dart  ← 직렬화/역직렬화
│   ├── sources/
│   │   ├── bluetooth_source.dart ← BLE 스캔
│   │   ├── firestore_source.dart ← 클라우드 업로드
│   │   └── sqlite_buffer.dart    ← 오프라인 큐
│   └── repositories/
│       └── buffer_repository_impl.dart ← 인터페이스 구현
└── presentation/providers/
    └── bridge_provider.dart      ← 오케스트레이터
```

---

## DFD Level 1

```mermaid
flowchart TD
    WD([웨어러블 기기\nBLE]) -->|"ScanResult"| BT["BluetoothSource\n① BLE 스캔\n② 폴백 시뮬레이션\n(1초마다 랜덤 패킷)"]

    NET_HW([네트워크 인터페이스]) --> NM["NetworkMonitor\nWiFi/LTE/이더넷\n감지"]

    BT -->|"Stream<Packet>"| BP
    NM -->|"Stream<bool>\nonlineStream"| BP

    BP["BridgeProvider\n오케스트레이터"]

    BP -->|"오프라인 저장"| BRI["BufferRepositoryImpl"]
    BRI --> SQ["SqliteBuffer\npacket_buffer.db"]

    BP -->|"온라인 즉시/배치 업로드"| FS["FirestoreSource"]
    FS -->|"HTTPS"| FC[(Cloud Firestore\npackets 컬렉션)]

    BP -->|"재연결 시 flush"| BRI
    BRI -->|"getPendingPackets()"| SQ
    SQ -->|"List<PacketModel>"| BRI
    BRI -->|"List<Packet>"| BP
    BP -->|"uploadPacket()"| FS
    BP -->|"deletePacket(id)"| BRI

    BG["BackgroundService\n(포그라운드 서비스)"] -.->|"프로세스 유지"| BP

    BP -->|"packetLog\nisOnline\npendingCount"| UI["DashboardScreen\n+ ConnectionStatusBar"]
```

---

## 데이터 흐름 상태 머신

```mermaid
stateDiagram-v2
    [*] --> Initializing: 앱 시작

    Initializing --> Scanning: BT 스캔 시작 + 네트워크 감시

    Scanning --> Online_Realtime: 네트워크 연결 + interval=realtime
    Scanning --> Online_Batch: 네트워크 연결 + interval=1s/3s/5s
    Scanning --> Offline: 네트워크 없음

    Online_Realtime --> UploadImmediate: 패킷 수신 즉시 Firestore 업로드
    Online_Batch --> BatchTimer: 패킷 수신 → pendingBatch에 추가
    BatchTimer --> FlushBatch: 타이머 만료 → 배치 전송
    Offline --> BufferSQLite: 패킷 수신 → SQLite 저장

    BufferSQLite --> FlushBuffer: 네트워크 재연결
    FlushBuffer --> Online_Realtime: 버퍼 비움 완료

    Online_Realtime --> Offline: 네트워크 끊김
    Online_Batch --> Offline: 네트워크 끊김
```

---

## Packet 데이터 구조

```
Packet (domain/entities)
├── id: String          "WEAR-XXXXXXXX"
├── timestamp: DateTime  수집 시각
├── heartRate: int       심박수 (55~104 bpm)
├── activity: int        활동량 (0~99)
└── sent: bool           Firestore 전송 완료 여부

PacketModel (data/models) — Packet 확장
├── fromMap(Map)         SQLite row → PacketModel
├── toSqlMap()           SQLite 저장용 Map
├── toFirestore()        Firestore 업로드용 Map
│   ├── timestamp: ISO8601
│   ├── heartRate
│   ├── activity
│   └── deviceId: id.split('-').first
└── copyWithSent(bool)   sent 상태 업데이트
```

---

## SQLite 스키마

```sql
CREATE TABLE packets (
  id        TEXT    PRIMARY KEY,
  timestamp INTEGER NOT NULL,   -- millisecondsSinceEpoch
  heartRate INTEGER NOT NULL,
  activity  INTEGER NOT NULL,
  sent      INTEGER NOT NULL DEFAULT 0  -- 0=미전송, 1=전송완료
);
```

미전송(`sent=0`) 패킷만 `getPending()`으로 조회하여 FIFO 순으로 flush.
