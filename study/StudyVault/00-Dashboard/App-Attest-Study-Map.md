---
module: dashboard
path: study/StudyVault/00-Dashboard
keywords: app-attest, device-check, onboarding, media-api
---

# NyangJup 학습 지도

#dashboard #onboarding #api-security

## 학습 순서

1. [[보안 구성요소와 책임 경계]]
2. [[등록 API와 상태별 요청 계약]]
3. [[재등록 보안 리뷰와 구현 흐름]]
4. [[고양이 API 연동 이슈38]]
5. [[미디어 API와 업로드·릴레이 화면 연동 이슈36]]
6. [[App Attest 복습 문제]]

## 최근 구현 학습 노트

- [[고양이 API 연동 이슈38]] — DTO/Entity, cursor 피드, App Attest 픽셀 요청
- [[미디어 API와 업로드·릴레이 화면 연동 이슈36]] — presigned PUT, HLS 처리 상태, Capture·RelayCat 레이아웃

## 태그 인덱스

| 태그 | 의미 |
|---|---|
| `#arch-*` | 책임 경계와 흐름 |
| `#module-*` | 기능·도메인 모듈 |
| `#api-*` | HTTP/OpenAPI 계약 |
| `#test-*` | 회귀·계약 테스트 |

## 검증 명령

```text
swift test
xcodebuild test -scheme NJPackage-Package -destination 'platform=iOS Simulator'
```
