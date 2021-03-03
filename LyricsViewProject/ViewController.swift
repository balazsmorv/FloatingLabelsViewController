//
//  ViewController.swift
//  LyricsViewProject
//
//  Created by Balázs Morvay on 2021. 03. 02..
//

import UIKit
import Combine

class MovingLabel: Equatable {
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



class ViewController: UIViewController {
    
    // MARK: - Customizations:
    
    /// Set this to affect the alpha of the labels.
    /// 0: Alpha is always 1.
    /// 1: Aplha is 1 on the middle of the view, and continously fades out, 0 on the top and buttom
    /// >1: Fades out sooner
    public var lineAlphaFactor: CGFloat = 3
    
    
    public var blurStyle: UIBlurEffect.Style = .dark
    
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
    
    public var fontSize: UIFont = UIFont.boldSystemFont(ofSize: 20)
    
    /// Extra lines, added to the bottom.
    /// 0: The last string will appear on the center of the screen at the end
    /// >0: The last string will go up this many times
    public var extraSpaceInBottom = 1
    
    public var animationLength: Double = 1.0
    
    public var scaleX: CGFloat = 1.5
    
    public var scaleY: CGFloat = 1.5
    
    public var textColor: UIColor = .white
    
    /// The publisher that controls the line movements.
    //public var timer = PassthroughSubject<Void, Never>()
    public var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().share()
    
    
    /// The texts that show up on screen
    public var texts = ["Hello!", "You fool!", "I love you!", "Come on join the joyride!",
                         "I hit the road", "Out of nowhere", "I had to jump in my car", "Be a rider",
                         "in a love game", "Following the stars..."]
    
    
    
    // MARK: - Properties
    
    private var bag = Set<AnyCancellable>()
    
    private var height = UIScreen.main.bounds.height
    private var width = UIScreen.main.bounds.width
    
    private var lineIndex = 0
    
    private var bottomLabelOffset: CGFloat = 0
    
    /// Lines that are top of the middle line
    private var lines = [MovingLabel]()
    
    private var indexToScale: Int = 0
    
    
    // MARK: - FUNCTIONS
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.height = self.view.bounds.height
        self.width = self.view.bounds.width
        
        let blurEffect = UIBlurEffect(style: self.blurStyle)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = view.bounds
        view.addSubview(blurredEffectView)
        
        
        // To see the middle of the view
//        let label = UILabel()
//        label.text = "--------------"
//        label.textColor = .white
//        label.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(label)
//        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        
        self.fillUpInitialLabels()

        
        timer.prefix((initialLabelNumber - 1) + (self.texts.count - initialLabelNumber) + extraSpaceInBottom)
            .sink {_ in
            print("tick")
            self.moveLinesUp()
            
            if self.lineIndex < self.texts.count {
                
                let newLine = self.animateNewLineIn(title: self.texts[self.lineIndex], with: self.animationLength)
                self.setAlpha(newLine, distanceFromCenter: self.distanceFromCenter(label: self.lines.last?.label))
                self.lines.append(MovingLabel(label: newLine, lastXTranslation: 0))
                
                self.lineIndex += 1
            } else {
                // Add emplty lines, to make the content continue to move up
                let newLine = self.animateNewLineIn(title: "", with: self.animationLength)
                self.lines.append(MovingLabel(label: newLine, lastXTranslation: 0))
            }
            
        }.store(in: &bag)
        
    }
    
    
    
    private func distanceFromCenter(label: UILabel?) -> CGFloat {
        if label == nil { return 0.0 }
        return abs(label!.frame.midY - self.height/2)
    }
    
    
    
    /// Places the initial labels on screen
    private func fillUpInitialLabels() {
        
        guard self.initialLabelNumber <= self.texts.count else { fatalError("Initial label number must be lower than or equal to the the number of strings") }
        
        var i = 0
        while i < self.initialLabelNumber + 1 {
            self.putInitialLine(title: self.texts[i])
            lineIndex += 1
            i += 1
        }
        var diffFromCenter = 0
        self.lines.forEach { (line) in
            diffFromCenter += Int((line.label.bounds.height + lineSpace))
        }
        self.bottomLabelOffset = CGFloat(diffFromCenter) - lineSpace
        
        if let label = self.lines.first?.label {
            applyScaleAndTranslation(with: 0, to: label, scaleX: 1.5, scaleY: 1.5)
        }
        
    }
    
    
    /// Moves every existing lines up.
    private func moveLinesUp() {
        
        self.lines.forEach { (line) in
            UIView.animate(withDuration: self.animationLength) { [self] in
                
                if line.label.frame.midY == height / 2 {
                    // We need to scale the label after this
                    let indexOfLabel = self.lines.firstIndex(of: line)
                    self.indexToScale = (indexOfLabel ?? -1) + 1
                }
                
                if self.lines.firstIndex(of: line) == indexToScale {
                    applyScaleAndTranslation(with: -(line.lastXTranslation + lineSpace), to: line.label, scaleX: 1.5, scaleY: 1.5)
                } else {
                    applyTranslationTransform(with: -(line.lastXTranslation + lineSpace), to: line.label)
                }
                
                line.lastXTranslation += lineSpace
                
                setAlpha(line.label, distanceFromCenter: self.distanceFromCenter(label: line.label))
            }
        }
        if self.lines.count == numberOfLines {
            self.lines.removeFirst().label.removeFromSuperview() // Free up the topmost label
        }
    }
    
    
    private func applyTranslationTransform(with points: CGFloat, to label: UILabel) {
        label.transform = CGAffineTransform.init(translationX: 0, y: points)
    }
    
    private func applyScaleAndTranslation(with points: CGFloat, to label: UILabel, scaleX: CGFloat, scaleY: CGFloat) {
        label.transform = CGAffineTransform.init(translationX: 0, y: points).scaledBy(x: scaleX, y: scaleY)
    }
    
    
    /// Creates the initial lines, and makes its constraints. 
    private func putInitialLine(title: String) {
        let newLine = UILabel()
        newLine.text = title
        newLine.textColor = self.textColor
        newLine.font = self.fontSize
        newLine.numberOfLines = 0

        newLine.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(newLine)

        var diffFromCenter = 0
        self.lines.forEach { (line) in
            diffFromCenter += Int((line.label.bounds.height + lineSpace))
        }

        newLine.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: CGFloat(diffFromCenter)).isActive = true
        newLine.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        newLine.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: self.leadingPadding).isActive = true
        newLine.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: self.trailingPadding).isActive = true
        
        self.setAlpha(newLine, distanceFromCenter: CGFloat(diffFromCenter))

        self.lines.append(MovingLabel(label: newLine, lastXTranslation: CGFloat(0)))
    }
    
    
    /// Creates a new UILabel, animates in to the center of the screen and returns it.
    private func animateNewLineIn(title: String, with duration: Double) -> UILabel {
        
        let newLine = UILabel()
        newLine.text = title
        newLine.textColor = self.textColor
        newLine.font = self.fontSize
        newLine.numberOfLines = 0
        
        self.view.addSubview(newLine)
        
        
        newLine.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: self.bottomLabelOffset).isActive = true
        newLine.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        newLine.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: self.leadingPadding).isActive = true
        newLine.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: self.trailingPadding).isActive = true
        
        newLine.translatesAutoresizingMaskIntoConstraints = false
        
        newLine.transform = CGAffineTransform(translationX: 0, y: self.height) // transform out of the screen, to the bottom
        
        UIView.animate(withDuration: duration) {
            newLine.transform = .identity // Transform back, so it comes from the bottom
        }
        
        return newLine
    }
    
    
    /// Sets the alpha, calculated by the distance from the center of the view
    private func setAlpha(_ label: UILabel, distanceFromCenter: CGFloat) {
        let normalizedDistance = distanceFromCenter / (self.height/2)
        label.alpha = 1 - (self.lineAlphaFactor * normalizedDistance)
    }


}

