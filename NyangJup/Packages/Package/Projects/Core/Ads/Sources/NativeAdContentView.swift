//
//  NativeAdView.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import UIKit
import SwiftUI

import CoreAdsInterface
import GoogleMobileAds

struct NativeAdContentView: UIViewRepresentable {
    private let item: NativeAdItem

    public init(item: NativeAdItem) {
        self.item = item
    }

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = .black

        let media = MediaView()
        media.contentMode = .scaleAspectFill
        media.clipsToBounds = true
        media.translatesAutoresizingMaskIntoConstraints = false

        let badge: UILabel = {
            let label = UILabel()
            label.text = Constant.badgeTitle
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .black
            label.backgroundColor = .white
            label.textAlignment = .center
            label.layer.cornerRadius = 4
            label.clipsToBounds = true

            return label
        }()

        let headline: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .bold)
            label.textColor = .white
            label.numberOfLines = 2

            return label
        }()

        let advertiser: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 13)
            label.textColor = .lightGray

            return label
        }()

        let callToAction: UIButton = {
            let button = UIButton(type: .system)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 12
            button.isUserInteractionEnabled = false

            return button
        }()

        let bottomStack = UIStackView(
            arrangedSubviews: [badge, headline, advertiser, callToAction]
        )
        bottomStack.axis = .vertical
        bottomStack.spacing = Constant.stackSpacing
        bottomStack.alignment = .leading
        bottomStack.setCustomSpacing(Constant.ctaTopSpacing, after: advertiser)
        bottomStack.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(media)
        adView.addSubview(bottomStack)

        NSLayoutConstraint.activate([
            media.topAnchor.constraint(equalTo: adView.topAnchor),
            media.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            media.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            media.bottomAnchor.constraint(equalTo: adView.bottomAnchor),

            bottomStack.leadingAnchor.constraint(
                equalTo: adView.leadingAnchor,
                constant: Constant.horizontalPadding
            ),
            bottomStack.trailingAnchor.constraint(
                lessThanOrEqualTo: adView.trailingAnchor,
                constant: -Constant.horizontalPadding
            ),
            bottomStack.bottomAnchor.constraint(
                equalTo: adView.bottomAnchor,
                constant: -Constant.bottomPadding
            ),

            badge.widthAnchor.constraint(equalToConstant: Constant.badgeWidth),
            badge.heightAnchor.constraint(equalToConstant: Constant.badgeHeight),
            callToAction.widthAnchor.constraint(equalToConstant: Constant.ctaWidth),
            callToAction.heightAnchor.constraint(equalToConstant: Constant.ctaHeight)
        ])

        adView.headlineView = headline
        adView.advertiserView = advertiser
        adView.mediaView = media
        adView.callToActionView = callToAction

        return adView
    }

    func updateUIView(_ adView: NativeAdView, context: Context) {
        guard let nativeAd = item.object as? NativeAd else { return }

        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        (adView.callToActionView as? UIButton)?
            .setTitle(nativeAd.callToAction, for: .normal)
        adView.mediaView?.mediaContent = nativeAd.mediaContent

        adView.advertiserView?.isHidden = nativeAd.advertiser == nil
        adView.callToActionView?.isHidden = nativeAd.callToAction == nil
        adView.nativeAd = nativeAd
    }
}

private extension NativeAdContentView {
    enum Constant {
        static let badgeTitle = "광고"

        static let badgeWidth: CGFloat = 34
        static let badgeHeight: CGFloat = 18
        static let ctaWidth: CGFloat = 170
        static let ctaHeight: CGFloat = 44
        static let stackSpacing: CGFloat = 6
        static let ctaTopSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let bottomPadding: CGFloat = 90
    }
}
