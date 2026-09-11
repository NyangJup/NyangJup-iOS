# Fastlane과 TestFlight 배포 가이드

이 문서는 처음 Fastlane을 사용하는 개발자가 NyangJup의 서명 자산을 준비하고 GitHub Actions로 TestFlight 빌드를 배포하는 방법을 설명한다.

## 1. 전체 흐름

PR 검증은 기존처럼 GitHub Actions가 `xcodebuild`를 직접 실행한다. PR에서는 앱을 Simulator용으로 빌드하고 Swift Package 테스트를 실행할 뿐, Apple 서명이나 TestFlight 자격증명을 사용하지 않는다.

배포할 때만 Fastlane을 사용한다.

```text
develop push
  -> Fastlane internal lane
  -> 운영 설정 검사
  -> match 서명 복원
  -> Release Archive
  -> Archive 설정 검사
  -> 내부 TestFlight 업로드

main의 v<앱 버전> 태그
  -> 태그가 main 커밋인지 검사
  -> Fastlane release lane
  -> 태그와 앱 버전 일치 검사
  -> 나머지는 internal과 같은 배포 과정
```

### PR에서 Fastlane을 사용하지 않는 이유

PR 빌드와 테스트는 `xcodebuild` 두 명령이면 충분하다. 여기에 Fastlane을 추가하면 Ruby와 gem 설치가 PR의 필수 조건이 되고, 실패 원인이 Xcode인지 Fastlane인지 확인할 단계가 늘어난다.

반면 배포에는 인증, 인증서 복원, 빌드 번호 조회, Archive, 업로드가 필요하다. Fastlane은 이 순서를 하나의 lane으로 묶고 개발자 PC와 CI에서 같은 방식으로 실행할 수 있어 배포에 사용할 가치가 크다.

## 2. Fastlane 용어

- **Fastlane**: Xcode와 App Store Connect 작업을 순서대로 실행하는 자동화 도구다.
- **lane**: 자동화 작업 하나를 의미한다. 이 저장소에는 `internal`, `release`, `bootstrap_signing`이 있다.
- **match**: 인증서와 provisioning profile을 암호화해 private Git 저장소에서 공동 관리하는 Fastlane 기능이다.
- **인증서**: Apple이 이 개발팀의 서명을 신뢰할 수 있다는 것을 증명한다. private key와 함께 사용한다.
- **provisioning profile**: 어떤 Bundle ID를 어떤 팀과 인증서로, 어떤 배포 방식으로 서명할 수 있는지 묶어 놓은 허가서다.
- **App Store Connect API Key**: CI가 Apple ID 비밀번호와 2단계 인증 없이 빌드 번호를 조회하고 TestFlight에 업로드할 때 사용한다.
- **Marketing Version**: 사용자에게 표시되는 버전이다. 현재 프로젝트 값이 `1.0`이면 태그는 `v1.0`이어야 한다.
- **Build Number**: 같은 Marketing Version 안에서 업로드를 구별하는 증가 숫자다. lane이 최신 TestFlight 번호에 1을 더한다.

## 3. 최초 Apple 설정

### Bundle ID와 앱 확인

Apple Developer의 Identifiers와 App Store Connect의 앱이 모두 다음 Bundle ID를 사용하는지 확인한다.

```text
com.colin.NyangJup
```

다른 Bundle ID로 이미 App Store Connect 앱을 만들었다면 workflow를 실행하기 전에 앱 등록을 바로잡아야 한다. Bundle ID는 기존 앱을 다른 앱으로 바꾸는 일반 설정값이 아니다.

### App Store Connect API Key 만들기

App Store Connect의 사용자 및 액세스에서 API Key를 만든다. 빌드 조회와 업로드, signing asset 관리에 필요한 권한만 부여한다. 생성 후 다음 세 값을 보관한다.

- Key ID
- Issuer ID
- 한 번만 내려받을 수 있는 `.p8` 파일

`.p8` 파일은 Git에 커밋하지 않는다. GitHub에는 base64 문자열로 저장한다.

```sh
base64 < AuthKey_XXXXXXXXXX.p8 | tr -d '\n'
```

출력 문자열 전체를 `ASC_KEY_P8_BASE64` Secret으로 등록한다.

## 4. match 저장소와 최초 서명 발급

match용 저장소는 앱 소스 저장소와 분리된 `NyangJup/ios-certificates` private 저장소를 사용한다. 이 저장소에는 암호화된 인증서와 profile만 저장한다.

로컬 셸에서 다음 환경변수를 준비한다. 실제 값은 셸 기록이나 문서에 남기지 않는다.

```sh
export ASC_KEY_ID="..."
export ASC_ISSUER_ID="..."
export ASC_KEY_P8_BASE64="..."
export MATCH_GIT_URL="git@github.com:NyangJup/ios-certificates.git"
export MATCH_PASSWORD="충분히 긴 임의의 암호"
```

저장소 루트에서 의존성을 설치하고 최초 signing asset을 만든다.

```sh
bundle config set --local path vendor/bundle
bundle install
bundle exec fastlane ios bootstrap_signing
```

`bundle config set --local path vendor/bundle`은 gem을 Homebrew 전역 경로가 아니라 이 프로젝트의 `vendor/bundle`에 설치한다. `/opt/homebrew` 권한 오류를 피하기 위해 `sudo bundle install`은 사용하지 않는다. `.bundle` 설정과 `vendor/bundle`은 Git에서 제외된다.

`bootstrap_signing`은 CI에서 실행되지 않는다. 권한이 있는 개발자 PC에서만 인증서와 App Store provisioning profile을 생성하거나 갱신한다.

### CI의 읽기 전용 접근

1. 별도의 SSH key pair를 만든다.
2. public key를 `NyangJup/ios-certificates` 저장소 Deploy Key로 등록한다.
3. **Allow write access는 켜지 않는다.**
4. private key 전체를 앱 저장소의 `MATCH_GIT_PRIVATE_KEY` Secret으로 등록한다.

CI의 Fastlane은 항상 `match(readonly: true)`를 사용한다. CI가 인증서를 새로 만들거나 기존 인증서를 변경할 수 없다는 뜻이다.

## 5. GitHub Environment 설정

앱 저장소의 Settings → Environments에서 `testflight` Environment를 만든다. 이번 구성은 태그 생성을 최종 승인으로 보기 때문에 별도의 required reviewer는 두지 않는다.

### Secrets

| 이름 | 의미 |
|---|---|
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_KEY_P8_BASE64` | `.p8` 파일을 한 줄로 base64 변환한 값 |
| `MATCH_PASSWORD` | match 저장소 암호화 비밀번호 |
| `MATCH_GIT_PRIVATE_KEY` | 인증서 저장소를 읽는 SSH private key |

### Variables

| 이름 | 의미 |
|---|---|
| `MATCH_GIT_URL` | `git@github.com:NyangJup/ios-certificates.git` |
| `BASE_URL` | 운영 API HTTPS URL |
| `MINIGAME_URL` | 운영 미니게임 HTTPS URL |
| `PRIVACY_POLICY_URL` | 공개 개인정보처리방침 HTTPS URL |
| `GAD_ID` | 운영 AdMob 앱 ID |
| `NATIVE_AD_ID` | 운영 네이티브 광고 단위 ID |
| `REWARD_AD_ID` | 운영 보상형 광고 단위 ID |

URL과 광고 ID는 앱 안의 `Info.plist`에서도 확인할 수 있어 비밀값은 아니다. 반면 `.p8`, match 암호, SSH private key는 반드시 Secret으로 등록한다.

## 6. 배포 방법

### 내부 TestFlight

PR이 `develop`에 병합되면 `Internal TestFlight` workflow가 자동 실행된다. 성공한 빌드는 App Store Connect의 TestFlight에 업로드된다.

App Store Connect에서 내부 테스터 그룹을 만들고 자동 배포를 켜야 Apple의 빌드 처리가 끝난 뒤 테스터에게 자동으로 보인다. Fastlane은 내부 빌드 업로드까지만 담당하며 외부 테스터 배포나 베타 심사를 요청하지 않는다.

### 태그 TestFlight

릴리즈할 main 커밋에서 프로젝트의 Marketing Version을 확인한다. 값이 `1.0`이라면 다음처럼 정확히 `v1.0` 태그를 사용한다.

```sh
git tag v1.0
git push origin v1.0
```

workflow는 태그 커밋이 `main`에 포함됐는지 확인한다. feature branch에 같은 이름의 태그를 붙여도 업로드되지 않는다. App Store 심사 제출, 메타데이터 확정, 실제 출시는 App Store Connect에서 수동으로 진행한다.

## 7. 자동 출시 게이트

Fastlane은 Archive 전에 다음 문제를 발견하면 즉시 중단한다.

- 필수 Secret이나 Variable 누락
- HTTPS가 아닌 운영 URL
- 형식이 잘못된 AdMob ID
- Google 샘플 광고 publisher ID 사용
- Release App Attest 설정이 `production`이 아님
- release 태그와 Marketing Version 불일치

Archive가 생성된 뒤에는 실제 앱 결과물에서 다음을 다시 검사한다.

- Bundle ID가 `com.colin.NyangJup`인지
- 운영 URL과 광고 ID가 정확히 들어갔는지
- signed App Attest entitlement가 `production`인지
- provisioning profile이 Bundle ID와 일치하고 만료되지 않았는지
- `PrivacyInfo.xcprivacy`가 포함됐는지

이 검사는 설정 파일만 맞고 실제 Archive가 잘못 생성되는 경우를 막는다. 실제 기기에서 App Attest 요청, 광고 노출과 보상 지급을 확인하는 절차는 GitHub #54 범위다.

## 8. 인증서 갱신

인증서 또는 profile 만료가 가까워지면 권한 있는 개발자가 로컬에서 `bootstrap_signing`을 다시 실행한다. match 저장소 변경을 확인한 다음 GitHub Actions를 재실행해 새 러너에서 복원되는지 검증한다.

일반적인 갱신 과정에서는 `match nuke`를 사용하지 않는다. 이 명령은 기존 인증서를 광범위하게 폐기할 수 있다. 인증서를 폐기해야 하는 상황이라면 영향받는 앱과 배포 담당자를 먼저 확인한다.

## 9. 실패 확인과 재실행

GitHub 저장소의 Actions 탭에서 실패한 workflow와 빨간색 step을 연다.

- `Configure read-only match access`: Deploy Key Secret 또는 인증서 저장소 접근 문제
- 환경변수 누락 메시지: `testflight` Environment의 Secret/Variable 문제
- `match`: 인증서, profile, match 암호 또는 Apple 권한 문제
- `build_app`: Xcode 컴파일 또는 서명 문제
- Archive 검증 메시지: Bundle ID, App Attest, 광고 ID, profile, privacy manifest 문제
- `upload_to_testflight`: App Store Connect API 권한 또는 Apple 처리 문제

원인을 수정한 뒤 해당 workflow의 **Re-run failed jobs**를 사용한다. 실패한 실행과 동시에 새 태그를 반복해서 만들지 않는다. 배포 workflow는 build number 충돌을 막기 위해 한 번에 하나씩 실행된다.
