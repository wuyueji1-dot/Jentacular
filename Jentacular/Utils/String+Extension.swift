//
//  String+Extension.swift
//  Jentacular
//
//  String utilities for validation, formatting, and localization helpers
//

import Foundation
import UIKit

extension String {
    // MARK: - Validation
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }

    var isValidIPAddress: Bool {
        let ipRegex = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        let ipPredicate = NSPredicate(format: "SELF MATCHES %@", ipRegex)
        return ipPredicate.evaluate(with: self)
    }

    var isValidHostname: Bool {
        let hostnameRegex = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"
        let hostnamePredicate = NSPredicate(format: "SELF MATCHES %@", hostnameRegex)
        return hostnamePredicate.evaluate(with: self) && count <= 253
    }

    var isAlphanumeric: Bool {
        !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }

    var isNumeric: Bool {
        !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    var isHexColor: Bool {
        let hexRegex = "^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"
        let hexPredicate = NSPredicate(format: "SELF MATCHES %@", hexRegex)
        return hexPredicate.evaluate(with: self)
    }

    // MARK: - Trimming
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var removingWhitespace: String {
        components(separatedBy: .whitespaces).joined()
    }

    var removingNewlines: String {
        components(separatedBy: .newlines).joined()
    }

    // MARK: - Case Conversion
    var camelCaseToWords: String {
        let pattern = "([a-z])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1 $2") ?? self
    }

    var snakeCaseToWords: String {
        replacingOccurrences(of: "_", with: " ").capitalized
    }

    var kebabCaseToWords: String {
        replacingOccurrences(of: "-", with: " ").capitalized
    }

    // MARK: - Localization
    var localized: String {
        L(self)
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }

    // MARK: - Substring
    func substring(from start: Int, to end: Int) -> String {
        let startIndex = index(self.startIndex, offsetBy: max(0, start))
        let endIndex = index(self.startIndex, offsetBy: min(count, end))
        return String(self[startIndex..<endIndex])
    }

    func safePrefix(_ maxLength: Int) -> String {
        String(prefix(maxLength))
    }

    // MARK: - Conversion
    var toDouble: Double? {
        Double(self)
    }

    var toInt: Int? {
        Int(self)
    }

    var toBool: Bool? {
        switch lowercased() {
        case "true", "yes", "1", "y": return true
        case "false", "no", "0", "n": return false
        default: return nil
        }
    }

    var toURL: URL? {
        URL(string: self)
    }

    // MARK: - Formatting
    var withLineBreaks: String {
        replacingOccurrences(of: "\\n", with: "\n")
    }

    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.width)
    }

    // MARK: - Masking
    var maskedIP: String {
        let parts = components(separatedBy: ".")
        guard parts.count == 4 else { return self }
        return "\(parts[0]).\(parts[1]).***.***"
    }

    var maskedEmail: String {
        let parts = components(separatedBy: "@")
        guard parts.count == 2, let first = parts.first else { return self }
        let maskedName = first.count > 2 ? first.prefix(2) + "***" : "***"
        return "\(maskedName)@\(parts[1])"
    }

    // MARK: - Hash
    var sha256Hash: String {
        // Simple hash for display purposes (not cryptographic)
        var hash: UInt64 = 5381
        for char in utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        return String(format: "%016llx", hash)
    }

    // MARK: - Random
    static func random(length: Int, charset: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
        String((0..<length).map { _ in charset.randomElement()! })
    }

    // MARK: - Regex
    func matches(pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
    }

    func replacingPattern(_ pattern: String, with replacement: String) -> String {
        replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }

    // MARK: - Base64
    var base64Encoded: String? {
        data(using: .utf8)?.base64EncodedString()
    }

    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - URL Encoding
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    var urlDecoded: String {
        removingPercentEncoding ?? self
    }
}

// MARK: - Optional String
extension Optional where Wrapped == String {
    var orEmpty: String {
        self ?? ""
    }

    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

// MARK: - Attributed String
extension String {
    func toAttributedString(with attributes: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {
        NSAttributedString(string: self, attributes: attributes)
    }

    func highlight(_ substring: String, color: UIColor) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        if let range = range(of: substring) {
            let nsRange = NSRange(range, in: self)
            attributedString.addAttribute(.foregroundColor, value: color, range: nsRange)
        }
        return attributedString
    }
}
