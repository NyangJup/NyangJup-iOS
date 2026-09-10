# 피드 스켈레톤 로딩 결정과 SwiftUI 구현

> 피드 전체 로딩 중 UI를 어떻게 보여 줄지에 대한 질문과 구현 결정을 현재 코드 기준으로 정리한 학습 노트다. 확정된 코드 동작과 대화 중 검토했지만 최종적으로 채택하지 않은 방향을 구분한다.

## 1. 문제: 피드 전체를 막는 로딩 화면이 부자연스럽다

### 궁금증과 제약

피드 API를 기다리는 동안 기존 `loadingOverlay`가 화면 전체를 가렸다. 이미지가 빠르게 로드되면 이미지 placeholder 스켈레톤은 거의 보이지 않지만, 피드 데이터 자체를 받는 동안에는 빈 흰 화면처럼 보일 수 있다. 반대로 실제 피드가 2개인데 임의의 6개 셀을 먼저 표시하면 응답 후 셀 수가 갑자기 줄어 레이아웃이 어색해질 수 있다.

### 검토한 선택지

| 선택지 | 장점 | 문제 또는 트레이드오프 | 결론 |
|---|---|---|---|
| 기존 `loadingOverlay` 유지 | 구현이 가장 단순함 | 화면 전체 조작을 막고 실제 콘텐츠 위치를 보여 주지 못함 | 제거 |
| 이미지 placeholder에만 스켈레톤 | 실제 콘텐츠 수와 항상 일치함 | API 응답 전 피드 영역은 빈 상태로 남음 | 중간 단계에서 검토 |
| 초기 셀을 임의 개수로 표시 | API 응답 전에도 피드 형태가 보임 | 실제 개수가 1~2개면 응답 순간 셀 수가 크게 바뀜 | 현재 9개로 채택 |

### 시간순 결정

1. `SharedDesign`에 재사용 가능한 `View.skeleton(isActive:)`를 추가하고, 피드의 두 `loadingOverlay`를 제거했다.
2. 실제 콘텐츠 개수가 2개인데 초기 가짜 셀 6개가 나타나는 문제가 확인되어, 이미지 placeholder 전용 스켈레톤으로 단순화하는 방향을 검토했다.
3. 인스타그램처럼 초기에는 일정한 개수의 셀을 보여 주는 UX를 비교하기 위해 초기 가짜 셀을 다시 유지하기로 했다.
4. 현재 구현은 최초 응답 전 3열 × 3행, 총 9개의 스켈레톤 셀을 표시하고, 응답 후에는 실제 `items`만 렌더링한다.

초기 9개는 서버의 실제 피드 개수를 의미하지 않는다. 이는 첫 화면의 구조적 빈 공간을 줄이기 위한 시각적 placeholder다. 따라서 응답 후 실제 개수로 전환되는 레이아웃 변화는 의도적으로 수용한 트레이드오프다.

## 2. 현재 피드 렌더링 흐름

```text
FeedViewModel.onAppear
        │
        ├─ isLoading && !hasLoadedInitialFeed
        │       └─ FeedList → 3열 × 3행 skeleton 9개
        │
        └─ 최초 응답 수신
                └─ FeedList → 실제 items만 표시
                           ├─ Media → FeedCell
                           └─ uploading → UploadingFeedCell

페이지네이션 로딩
        └─ 기존 items 유지 + 다음 페이지 요청
           (추가 가짜 skeleton 셀 없음)
```

`FeedView`는 `isLoading && !hasLoadedInitialFeed`를 `FeedList`에 전달한다. `FeedList`는 이 값이 참일 때 `initialSkeletonCount = 9`를 사용하고, 거짓이면 `items`를 순회한다. 실제 아이템을 표시하는 분기에는 기존 `.onAppear` 기반 페이지네이션 트리거가 유지된다.

전체 화면을 덮던 `.loadingOverlay(isPresented:)` 두 곳은 `FeedView`에서 제거되었다. 따라서 페이지네이션 중 기존 셀을 덮거나 상호작용을 차단하지 않는다.

## 3. 이미지 로딩은 `NZAsyncImage` placeholder가 담당한다

초기 피드 셀과 별개로, 서버 응답 후 실제 셀의 이미지가 늦게 도착할 수 있다. 이 경우 이미지가 들어갈 자리의 크기를 먼저 확보하고 placeholder에만 스켈레톤을 적용한다.

| 위치 | 로딩 중 placeholder | 이미지 도착 후 |
|---|---|---|
| `FeedCell` 썸네일 | target size의 `Rectangle().skeleton()` | 실제 이미지로 교체 |
| `CatProfileInfoView` 아바타 | 지정 크기의 `Circle().skeleton()` | `CatAvatarView`로 교체 |
| `RelayCatCell` 아바타 | 지정 크기의 `Circle().skeleton()` | `CatAvatarView`로 교체 |

`NZAsyncImage`의 내부 이미지 상태가 변경되면 placeholder View subtree가 실제 이미지 subtree로 바뀐다. 따라서 이미지 로딩 완료 시 `skeleton(isActive: false)`를 직접 호출하는 것이 아니라, 스켈레톤이 포함된 placeholder 자체가 View 트리에서 제거된다. placeholder의 크기를 실제 이미지와 동일하게 설정했기 때문에 이미지 도착 전후 레이아웃 이동을 줄인다.

업로드 중인 항목은 이 흐름과 별개다. `UploadingFeedCell`의 `ProgressView`는 진행 상태 표현이므로 변경하지 않는다.

## 4. `View.skeleton(isActive:)`가 modifier 하나로 동작하는 이유

공개 API는 다음 형태다.

```swift
@ViewBuilder
func skeleton(isActive: Bool = true) -> some View {
    if isActive {
        modifier(SkeletonModifier())
    } else {
        self
    }
}
```

`isActive`를 `SkeletonModifier` 내부의 `@State`나 `@Binding`으로 관찰하지 않는 것은 의도된 구조다. SwiftUI에서 `isActive`를 가진 부모의 상태가 바뀌면 부모 `body`가 다시 계산되고, `.skeleton(isActive:)` 호출도 새 Bool 값으로 다시 평가된다.

```text
isActive = true
  → SkeletonModifier가 붙은 View를 생성

isActive = false
  → 원본 self를 생성
  → 기존 SkeletonModifier subtree 제거
```

`@ViewBuilder`는 두 결과를 조건부 View로 묶어 주므로 하나의 공개 modifier API처럼 사용할 수 있다. 실제 현재 호출부 대부분은 `.skeleton()`을 사용한다. 이 경우 `NZAsyncImage` 또는 `FeedList`의 상위 분기가 placeholder/skeleton을 View 트리에서 추가하거나 제거하는 것이 상태 전환의 주체다.

따라서 상태 관찰 지점은 modifier가 아니라 다음과 같다.

| 상태 | 관찰·변경 주체 | 스켈레톤 결과 |
|---|---|---|
| 최초 피드 로딩 | `FeedViewModel.state` | `FeedList`가 9개 셀 분기를 선택 |
| 이미지 로딩 | `NZAsyncImage` 내부 상태 | placeholder subtree가 실제 이미지로 교체 |
| pulse 진행 | `SkeletonModifier`의 `@State isPulseHighlighted` | 같은 placeholder 내부 색상 변화 |
| Reduce Motion | SwiftUI `accessibilityReduceMotion` 환경값 | 애니메이션 없이 base 색상만 표시 |

## 5. Pulse 선택과 자연스러움 조정

### 처음의 shimmer와 비교

초기에는 회색 베이스 위를 밝은 gradient 띠가 이동하는 shimmer를 사용했다. 이동 방향과 시작점이 매번 달라 보이거나, 반복 순간에 갑자기 연결되는 느낌이 있어 자연스럽지 않다는 피드백이 있었다.

두 번째 대안은 밝은 띠의 이동 대신 셀 전체 명도가 천천히 변하는 pulse였다. 이 방식은 작은 원형 아바타와 큰 피드 셀 모두에서 형태가 단순하고, 밝은 띠가 경계를 가로지를 때 생기는 시각적 단절이 없다. 현재는 이 두 번째 pulse를 채택했다.

### 현재 pulse 구현

`SkeletonModifier`는 원본 View의 레이아웃과 모양을 보존하면서 색상만 덧씌운다.

```swift
content
    .hidden()          // 크기와 레이아웃 유지
    .overlay { pulseColor }
    .mask { content }  // Circle, Rectangle 등 원본 모양 유지
```

명암과 속도는 비교 후 다음처럼 조정되었다.

| 환경 | 기본 opacity | 강조 opacity | 단계 시간 |
|---|---:|---:|---:|
| 라이트 모드 | `0.12` | `0.27` | `0.9초` |
| 다크 모드 | `0.18` | `0.34` | `0.9초` |

`withAnimation(.easeInOut(duration: 0.9))`으로 `isPulseHighlighted`를 반복 전환한다. 기본값과 강조값의 차이를 너무 작게 두면 스켈레톤이 거의 보이지 않고, 너무 크게 두면 로딩 오류나 번쩍임처럼 보일 수 있다. 현재 값은 “조금 더 티 나게”라는 시각 피드백에 맞춰 이전 pulse보다 대비와 속도를 높인 값이다.

### Reduce Motion

`@Environment(\.accessibilityReduceMotion)`이 참이면 애니메이션 Task를 시작하지 않고 기본 opacity만 렌더링한다. 환경값이 바뀌면 `.task(id: accessibilityReduceMotion)`가 다시 평가되어 애니메이션 생명주기도 환경 설정에 맞춰진다.

## 6. 코드 책임과 파일 맵

| 책임 | 현재 위치 |
|---|---|
| 공개 skeleton API와 pulse modifier | `Packages/Package/Projects/Shared/Design/Sources/Modifiers/SkeletonModifier.swift` |
| 최초 9개와 실제 피드 셀 분기 | `Packages/Package/Projects/Feature/Home/Sources/View/Feed/FeedList.swift` |
| 최초 로딩 플래그 전달·overlay 제거 | `Packages/Package/Projects/Feature/Home/Sources/View/Feed/FeedView.swift` |
| 피드 썸네일 placeholder | `Packages/Package/Projects/Feature/Home/Sources/View/Feed/FeedCell.swift` |
| 피드 고양이 아바타 placeholder | `Packages/Package/Projects/Feature/Home/Sources/Components/CatProfileInfoView.swift` |
| 릴레이 고양이 아바타 placeholder | `Packages/Package/Projects/Feature/RelayCat/Sources/View/RelayCatCell.swift` |

## 7. 검증 포인트와 남은 트레이드오프

확인해야 할 동작은 다음과 같다.

1. 최초 API 응답 전 정확히 9개가 3열로 나타나는가.
2. 응답 후 서버가 반환한 실제 개수로 전환되고, 페이지네이션 중 기존 셀이 유지되는가.
3. 썸네일·아바타 이미지가 늦게 도착해도 해당 자리만 placeholder에서 이미지로 바뀌는가.
4. 전체 화면을 막는 `loadingOverlay`가 없어 페이지네이션 중 셀 조작이 가능한가.
5. 라이트·다크 모드에서 pulse가 보이되 과도하게 번쩍이지 않는가.
6. Reduce Motion에서 색상 변화 없이 정적인 placeholder가 표시되는가.

현재 테스트 계획에는 `FeatureHome`, `FeatureRelayCat` Simulator 빌드가 포함되어 있으며, 실제 시각적 자연스러움은 라이트·다크 모드와 Reduce Motion 설정에서 직접 확인해야 한다. 초기 9개를 고정하는 선택은 첫 화면의 빈 공간을 줄이는 대신, 실제 콘텐츠가 적은 사용자의 응답 순간 셀 수가 줄어드는 레이아웃 변화를 감수한다. 이 UX가 실제 데이터 분포에서 어색하면 서버 feed count를 사용해 skeleton 개수를 예측하는 별도 계약이 필요하지만, 이번 범위에서는 서버 변경 없이 고정 9개를 유지한다.

삭제 상태인 기존 사용자 소유 문서 `study/capture-feed-session-2026-07-27.md`와 `study/media-upload-and-feed-state.md`는 복구하거나 수정하지 않았다.

## Related Notes

- `study/Home/feed-data-viewmodel.md`
- `study/ImageLoader/01-Image-Caching-Architecture.md`
- `study/SwiftUI/swiftui-view-update-optimization.md`
