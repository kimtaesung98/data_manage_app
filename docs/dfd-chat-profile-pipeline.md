# DFD — 사용자 프로필 + AI 채팅 파이프라인

## 개요

Supabase를 백엔드로 사용하는 두 가지 기능:
1. **사용자 프로필 CRUD** — Google OAuth 로그인 후 `user_profiles` 테이블 관리
2. **AI 채팅** — Supabase Edge Function을 통해 Anthropic Claude API 호출

---

## 관련 파일

```
lib/
├── chat/
│   ├── models/
│   │   ├── conversation.dart       ← 대화 엔티티
│   │   └── message.dart            ← 메시지 엔티티
│   ├── pages/
│   │   ├── login_page.dart         ← OAuth 로그인 UI
│   │   ├── chat_list_page.dart     ← 대화 목록
│   │   └── chat_page.dart          ← 채팅 UI
│   ├── providers/
│   │   └── chat_auth_provider.dart ← Supabase 세션 상태
│   └── services/
│       └── supabase_chat_service.dart ← DB + Edge Function
├── profile/
│   ├── models/
│   │   └── user_profile.dart       ← 프로필 엔티티
│   ├── pages/
│   │   ├── profile_dashboard_page.dart ← 홈 화면
│   │   └── edit_profile_page.dart  ← 편집 UI
│   ├── providers/
│   │   └── profile_provider.dart   ← 프로필 상태 관리
│   └── services/
│       └── profile_service.dart    ← Supabase CRUD
└── supabase/migrations/
    └── 20240101000000_user_profiles.sql ← DB 스키마 + RLS
```

---

## DFD Level 1 — 인증 + 프로필

```mermaid
flowchart TD
    subgraph Auth["인증 흐름"]
        GOOGLE([Google OAuth\n서버]) -->|"access_token"| CAP["ChatAuthProvider\n세션 감시"]
        CAP -->|"User? / isAuthenticated"| AG["_AuthGate\n(main.dart)"]
        AG -->|"인증됨"| PD["ProfileDashboardPage"]
        AG -->|"미인증"| LP["LoginPage"]
        LP -->|"signInWithGoogle()"| CAP
    end

    subgraph Profile["프로필 CRUD 흐름"]
        PD --> PP["ProfileProvider\nidle/loading/loaded/error"]
        PP -->|"loadProfile()"| PS["ProfileService"]
        PS -->|"SELECT WHERE id=uid"| TBL[(Supabase\nuser_profiles)]
        TBL -->|"row or null"| PS
        PS -->|"null → createFromGoogle()"| META["Google OAuth\nuserMetadata"]
        META -->|"full_name, avatar_url"| PS
        PS -->|"upsert"| TBL
        TBL -->|"UserProfile"| PP
        PP -->|"profile"| PD

        PD -->|"편집"| EP["EditProfilePage"]
        EP -->|"updateProfile(nickname, avatarUrl)"| PP
        PP -->|"ProfileService.updateProfile()"| PS
        PS -->|"UPDATE"| TBL

        PD -->|"삭제"| PP
        PP -->|"ProfileService.deleteProfile()"| PS
        PS -->|"DELETE WHERE id=uid"| TBL
    end
```

---

## DFD Level 1 — AI 채팅

```mermaid
flowchart TD
    subgraph ChatList["대화 목록"]
        CLP["ChatListPage"] -->|"fetchConversations()"| SCS["SupabaseChatService"]
        SCS -->|"SELECT ORDER BY created_at DESC"| CONV_TBL[(conversations)]
        CONV_TBL -->|"List<Conversation>"| SCS
        SCS -->|"List<Conversation>"| CLP

        CLP -->|"createConversation(title)"| SCS
        SCS -->|"INSERT {user_id, title}"| CONV_TBL

        CLP -->|"deleteConversation(id)"| SCS
        SCS -->|"DELETE WHERE id"| CONV_TBL
    end

    subgraph ChatRoom["채팅 방"]
        CLP -->|"Conversation"| CP["ChatPage"]
        CP -->|"messagesStream(conversationId)"| SCS
        SCS -->|"stream.eq('conversation_id')"| MSG_TBL[(messages)]
        MSG_TBL -->|"Realtime Stream<List<Message>>"| CP

        CP -->|"sendToClaude(history, message)"| SCS
        SCS -->|"functions.invoke('chat')"| EF["Edge Function\n'chat'"]
        EF -->|"INSERT user 메시지"| MSG_TBL
        EF -->|"POST /v1/messages"| CLAUDE([Anthropic\nClaude API])
        CLAUDE -->|"assistant 응답"| EF
        EF -->|"INSERT assistant 메시지"| MSG_TBL
        EF -->|"{ reply: string }"| SCS
        SCS -->|"reply"| CP
    end
```

---

## 낙관적 업데이트 (Optimistic UI)

```mermaid
sequenceDiagram
    participant U as 사용자
    participant CP as ChatPage
    participant SCS as SupabaseChatService
    participant RT as Supabase Realtime
    participant EF as Edge Function

    U->>CP: 메시지 입력 + 전송 탭
    CP->>CP: _optimistic 목록에 임시 메시지 추가 (opacity 0.6)
    CP->>CP: _sending = true → LinearProgressIndicator 표시
    CP->>SCS: sendToClaude(...)
    SCS->>EF: functions.invoke('chat')
    EF-->>SCS: { reply: "..." }
    RT-->>CP: messagesStream 업데이트 (user + assistant 메시지)
    CP->>CP: _optimistic 목록 비움
    CP->>CP: _sending = false
    Note over CP: 실제 메시지로 교체 완료
```

---

## 데이터 구조

### UserProfile

```
UserProfile
├── id: String (UUID)         Supabase auth.users.id와 동일
├── nickname: String?         표시명 (nullable)
├── avatarUrl: String?        프로필 이미지 URL (nullable)
└── updatedAt: DateTime       마지막 수정 시각 (트리거 자동 갱신)
```

### Conversation

```
Conversation
├── id: String (UUID)
├── userId: String (UUID)     auth.users.id FK
├── title: String             대화 제목
└── createdAt: DateTime
```

### Message

```
Message
├── id: String (UUID)
├── conversationId: String    conversations.id FK
├── role: MessageRole         user | assistant
├── content: String           메시지 본문
└── createdAt: DateTime
```

---

## Supabase 테이블 구조 및 RLS

```
user_profiles
├── id UUID PK → auth.users(id) ON DELETE CASCADE
├── nickname TEXT
├── avatar_url TEXT
└── updated_at TIMESTAMPTZ (트리거 자동 관리)

RLS 정책: 모든 CRUD 작업에 auth.uid() = id 조건 적용
→ 각 사용자는 자신의 행에만 접근 가능
```

Edge Function `chat`에서 Anthropic API 키가 필요합니다.  
Supabase 대시보드 → Edge Functions → Secrets에 `ANTHROPIC_API_KEY` 등록 필요.
