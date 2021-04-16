//
//  FloatingLabelsView.swift
//
//  Created for Adapt in 2021.
//  🦖rawr

import Combine
import UIKit

/// Contains all the customization properties for the FloatingLabelsView view.
struct FloatingLabelsViewModel {
    /// Set this to affect the alpha of the labels.
    /// 0: Alpha is always 1.
    /// 1: Aplha is 1 on the middle of the view, and continously fades out, 0 on the top and buttom
    /// >1: Fades out sooner
    public var lineAlphaFactor: CGFloat = 3

    /// Set this to affect the alpha of the labels on the bottom half of the view.
    public var bottomAlphaFactor: CGFloat = 2

    /// The number of lines in the `lines` buffer.
    /// This is the maximum number of lines that are visible on the screen.
    /// Note that the actually visible lines may be fewer, because of the alpha factor `self.alphaLineFactor`
    public var numberOfLines = 10

    /// The initial number of lines present on the screen.
    public var initialLabelNumber = 3

    /// Leading padding. If the label is scaled with `scaleX`, this padding is not gonna stop the content from outstrech the screen.
    public var leadingPadding: CGFloat = 12

    /// Trailing padding. If the label is scaled with `scaleX`, this padding is not gonna stop the content from outstrech the screen.
    public var trailingPadding: CGFloat = 12

    /// The space between lines. Make sure to give ths a big enough number, otherwise the labels may overlap
    public var lineSpace: CGFloat = 50

    public var font: UIFont = UIFont.boldSystemFont(ofSize: 20)

    /// Extra lines, added to the bottom.
    /// 0: The last string will appear on the center of the screen at the end
    /// >0: The last string will go up this many times
    public var extraSpaceInBottom = 1

    public var animationLength: Double = 1.0

    public var scaleX: CGFloat = 1.5

    public var scaleY: CGFloat = 1.5

    public var textColor: UIColor = .white

    /// The publisher that controls the line movements.
    public var timer: AnyPublisher<Date, Never>

    /// The texts that show up on screen
    public var texts = ["Hello!", "You fool!", "I love you!", "Come on join the joyride!",
                        "I hit the road", "Out of nowhere", "I had to jump in my car", "Be a rider",
                        "in a love game", "Following the stars..."]
}

class FloatingLabelsView: UIView {
    private class MovingLabel: Equatable {
        static func == (lhs: MovingLabel, rhs: MovingLabel) -> Bool {
            return lhs.label == rhs.label
        }

        let label: UILabel
        var lastXTranslation: CGFloat
        init(label: UILabel, lastXTranslation: CGFloat) {
            self.label = label
            self.lastXTranslation = lastXTranslation
        }
    }

    // MARK: - Properties

    private var bag = Set<AnyCancellable>()

    private var height = UIScreen.main.bounds.height
    private var width = UIScreen.main.bounds.width

    private var lineIndex = 0

    private var bottomLabelOffset: CGFloat = 0

    /// Lines that are top of the middle line
    private var lines = [MovingLabel]()

    private var indexToScale: Int = 0

    private var blurredEffectView: UIVisualEffectView!

    /// Set this, so it can dismiss itself.
    public var parentVC: UIViewController?

    /// Set this to the blur style you want to see
    public var blurStyle: UIBlurEffect.Style = .dark

    /// Set this property to start the label movements. Until it is not set, the view displays a simple blur, with a style specified in `blurStyle`.
    public var viewModel: FloatingLabelsViewModel? {
        didSet {
            guard viewModel != nil else { return }
            fillUpInitialLabels()
            setupLabels()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {

        let blurEffect = UIBlurEffect(style: blurStyle)
        blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.alpha = 1

        addSubview(blurredEffectView)
//        blurredEffectView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
        
        blurredEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        blurredEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        blurredEffectView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        blurredEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    /// Sets up the subscription to the publisher that indicates when to move the labels
    private func setupLabels() {
        guard let vm = viewModel else { return }
        guard let viewModel = viewModel else { return }
        guard viewModel.texts.count > 0 else { return }
        let initialLabelMovement = viewModel.initialLabelNumber == 0 ? 0 : viewModel.initialLabelNumber - 1
        viewModel.timer
            .prefix((initialLabelMovement) + (viewModel.texts.count - viewModel.initialLabelNumber) + viewModel.extraSpaceInBottom)
            .sink { _ in

                // Let the last animation play, before dismissing the view.
                DispatchQueue.main.asyncAfter(deadline: .now() + viewModel.animationLength * 2) {
                    UIView.animate(withDuration: 0.3) {
                        self.lines.forEach { label in
                            label.label.alpha = 0
                        }
                    }
                    UIView.animate(withDuration: 1) {
                        self.blurredEffectView.alpha = 0
                    } completion: { _ in
                        self.removeFromSuperview()
                    }
                }

            } receiveValue: { _ in

                self.moveLinesUp()

                if self.lineIndex < viewModel.texts.count {
                    let newLine = self.animateNewLineIn(title: viewModel.texts[self.lineIndex], with: viewModel.animationLength)
                    self.setAlpha(newLine, distanceFromCenter: self.distanceFromCenter(label: self.lines.last?.label))
                    self.lines.append(MovingLabel(label: newLine, lastXTranslation: 0))

                    self.lineIndex += 1
                } else {
                    // Add emplty lines, to make the content continue to move up
                    let newLine = self.animateNewLineIn(title: "", with: viewModel.animationLength)
                    self.lines.append(MovingLabel(label: newLine, lastXTranslation: 0))
                }

            }.store(in: &bag)
    }

    /// Places the initial labels on screen
    private func fillUpInitialLabels() {
        guard let viewModel = viewModel else { return }
        guard viewModel.initialLabelNumber <= viewModel.texts.count else { return } // fatalError("Initial label number must be lower than or equal to the the number of strings") }

        var i = 0
        while i < min(viewModel.initialLabelNumber + 1, viewModel.texts.count - 1) {
            putInitialLine(title: viewModel.texts[i])
            lineIndex += 1
            i += 1
        }
        var diffFromCenter = 0
        lines.forEach { line in
            diffFromCenter += Int(line.label.bounds.height + viewModel.lineSpace)
        }
        bottomLabelOffset = CGFloat(diffFromCenter) - viewModel.lineSpace

        if let label = lines.first?.label {
            applyScaleAndTranslation(with: 0, to: label, scaleX: viewModel.scaleX, scaleY: viewModel.scaleY)
        }
    }

    /// Moves every existing lines up.
    private func moveLinesUp() {
        guard let viewModel = viewModel else { return }
        lines.forEach { line in
            UIView.animate(withDuration: viewModel.animationLength) { [self] in

                if line.label.frame.midY == height / 2 {
                    // We need to scale the label after this
                    let indexOfLabel = self.lines.firstIndex(of: line)
                    self.indexToScale = (indexOfLabel ?? -1) + 1
                }

                if self.lines.firstIndex(of: line) == indexToScale {
                    applyScaleAndTranslation(with: -(line.lastXTranslation + viewModel.lineSpace), to: line.label, scaleX: viewModel.scaleX, scaleY: viewModel.scaleY)
                } else {
                    applyTranslationTransform(with: -(line.lastXTranslation + viewModel.lineSpace), to: line.label)
                }

                line.lastXTranslation += viewModel.lineSpace

                setAlpha(line.label, distanceFromCenter: self.distanceFromCenter(label: line.label))
            }
        }
        if lines.count == viewModel.numberOfLines + viewModel.initialLabelNumber + viewModel.initialLabelNumber {
            lines.removeFirst().label.removeFromSuperview() // Free up the topmost label
        }
    }

    private func distanceFromCenter(label: UILabel?) -> CGFloat {
        if label == nil { return 0.0 }
        return abs(label!.frame.midY - height / 2)
    }

    private func applyTranslationTransform(with points: CGFloat, to label: UILabel) {
        label.transform = CGAffineTransform(translationX: 0, y: points)
    }

    private func applyScaleAndTranslation(with points: CGFloat, to label: UILabel, scaleX: CGFloat, scaleY: CGFloat) {
        label.transform = CGAffineTransform(translationX: 0, y: points).scaledBy(x: scaleX, y: scaleY)
    }

    /// Creates the initial lines, and makes its constraints.
    private func putInitialLine(title: String) {
        guard let viewModel = viewModel else { return }

        let newLine = UILabel()
        newLine.text = title
        newLine.textColor = viewModel.textColor
        newLine.font = viewModel.font
        newLine.numberOfLines = 0

        newLine.translatesAutoresizingMaskIntoConstraints = false

        var diffFromCenter = 0
        lines.forEach { line in
            diffFromCenter += Int(line.label.bounds.height + viewModel.lineSpace)
        }

        newLine.alpha = 0.0

        UIView.animate(withDuration: viewModel.animationLength) {
            self.setAlpha(newLine, distanceFromCenter: CGFloat(diffFromCenter))
            self.addSubview(newLine)
        }

        newLine.centerYAnchor.constraint(equalTo: centerYAnchor, constant: CGFloat(diffFromCenter)).isActive = true
        newLine.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        newLine.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: viewModel.leadingPadding).isActive = true
        newLine.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: viewModel.trailingPadding).isActive = true

        lines.append(MovingLabel(label: newLine, lastXTranslation: CGFloat(0)))
    }

    /// Creates a new UILabel, animates in to the center of the screen and returns it.
    private func animateNewLineIn(title: String, with duration: Double) -> UILabel {
        guard let viewModel = viewModel else { fatalError("This function should not be called when the viewmodel is nil.") }

        let newLine = UILabel()
        newLine.text = title
        newLine.textColor = viewModel.textColor
        newLine.font = viewModel.font
        newLine.numberOfLines = 0

        addSubview(newLine)

        newLine.centerYAnchor.constraint(equalTo: centerYAnchor, constant: bottomLabelOffset).isActive = true
        newLine.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        newLine.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: viewModel.leadingPadding).isActive = true
        newLine.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: viewModel.trailingPadding).isActive = true

        newLine.translatesAutoresizingMaskIntoConstraints = false

        newLine.transform = CGAffineTransform(translationX: 0, y: height) // transform out of the screen, to the bottom

        UIView.animate(withDuration: duration) {
            newLine.transform = .identity // Transform back, so it comes from the bottom
        }

        return newLine
    }

    /// Sets the alpha, calculated by the distance from the center of the view
    private func setAlpha(_ label: UILabel, distanceFromCenter: CGFloat) {
        guard let viewModel = viewModel else { return }
        let alphaFactor: CGFloat

        // If the labels frame is in the top half of the screen, apply the `viewModel.lineAlphaFactor`, else, apply the `viewModel.bottomAlphaFactor`.
        // If the labels frame.midY == 0, then the label has just been added, and therefore should be treated as a new label coming from the bottom.
        if label.frame.midY <= height / 2, label.frame.midY != 0.0 {
            alphaFactor = viewModel.lineAlphaFactor
        } else {
            alphaFactor = viewModel.bottomAlphaFactor
        }

        let normalizedDistance = distanceFromCenter / (height / 2)
        label.alpha = 1 - (alphaFactor * normalizedDistance)
    }
}
