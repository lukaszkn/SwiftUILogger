import SwiftUI
import OrderedCollections

///
open class SwiftUILogger: ObservableObject {
    ///
    public enum Level: Int {
        case success, info, warning, error, fatal
        
        var color: Color {
            switch self {
            case .success: return .green
            case .info: return .blue
            case .warning: return .yellow
            case .error: return .red
            case .fatal: return .purple
            }
        }
        
        var emoji: Character {
            switch self {
            case .success: return "🟢"
            case .info: return "🔵"
            case .warning: return "🟡"
            case .error: return "🔴"
            case .fatal: return "🟣"
            }
        }
    }
    
    ///
    public struct Event: Identifiable {
        public struct Metadata {
            public let file: StaticString
            public let line: Int
            public let tags: [any LogTagging]
            
            public init(
                file: StaticString,
                line: Int,
                tags: [any LogTagging]
            ) {
                self.file = file
                self.line = line
                self.tags = tags
            }
        }
        
        static let dateFormatter: DateFormatter = {
            var formatter = DateFormatter()
            
            formatter.timeStyle = .none
            formatter.dateStyle = .short
            
            return formatter
        }()
        
        static let timeFormatter: DateFormatter = {
            var formatter = DateFormatter()
            
            formatter.timeStyle = .long
            formatter.dateStyle = .none
            
            return formatter
        }()
        
        static let dateTimeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            return formatter
        }()
        
        ///
        public let id: UUID
        
        ///
        public let dateCreated: Date
        
        ///
        public let level: Level
        
        ///
        public let message: String
        
        ///
        public let error: Error?
        
        ///
        public let metadata: Metadata
        
        ///
        public init(
            level: Level,
            message: String,
            error: Error? = nil,
            tags: [any LogTagging] = [],
            _ file: StaticString = #fileID,
            _ line: Int = #line
        ) {
            self.id = UUID()
            self.dateCreated = Date()
            self.level = level
            self.message = message
            self.error = error
            self.metadata = .init(
                file: file,
                line: line,
                tags: tags
            )
        }
    }
    
    ///
    public static var `default`: SwiftUILogger = SwiftUILogger()
    
    ///
    private var lock: NSLock
    
    ///
    public let name: String?
    
    ///
    @Published var filteredTags: OrderedSet<String>
    
    ///
    public var logToConsole: Bool = false
    
    ///
    public var enabled: Bool = true

    ///
    @Published public var logs: [Event]
    public var displayedLogs: [Event] {
        return filteredTags.isEmpty
        ? logs
        : logs.filter {
            $0.metadata.tags.first(
                where: { filteredTags.contains($0.value) }
            ) != nil
        }
    }
    
    ///
    open var blob: String {
        lock.lock()
        defer { lock.unlock() }
        
        return displayedLogs
            .map { (event) -> String in
                let dateTime = Event.dateTimeFormatter.string(from: event.dateCreated)
                let emoji = event.level.emoji.description
                let eventMessage = "\(dateTime) \(emoji): \(event.message) (File: \(event.metadata.file)@\(event.metadata.line))"
                
                guard let error = event.error else {
                    return eventMessage
                }
                
                return eventMessage + "(Error: \(error.localizedDescription))"
            }
            .joined(separator: "\n")
    }
    
    ///
    public init(
        name: String? = nil,
        logs: [Event] = [],
        logToConsole: Bool = false
    ) {
        self.lock = NSLock()
        self.name = name
        self.logs = logs
        
        self.filteredTags = []
        self.logToConsole = logToConsole
    }
    
    ///
    open func log(
        level: Level,
        message: String,
        error: Error? = nil,
        tags: [any LogTagging] = [],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        if !enabled {
            return
        }
        
        guard Thread.isMainThread else {
            return DispatchQueue.main.async {
                self.log(level: level, message: message, error: error, tags: tags, file, line)
            }
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        logs.append(
            Event(
                level: level,
                message: message,
                error: error,
                tags: tags,
                file,
                line
            )
        )
        
        if logToConsole {
            if let event = logs.last {
                let dateTime = Event.dateTimeFormatter.string(from: event.dateCreated)
                print("\(dateTime) \(event.level.emoji.description): \(event.message)")
            }
        }
    }
    
    ///
    open func success(
        message: String,
        tags: [any LogTagging] = [],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .success,
            message: message,
            error: nil,
            tags: tags,
            file,
            line
        )
    }
    
    ///
    open func info(
        message: String,
        tags: [any LogTagging] = [],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .info,
            message: message,
            error: nil,
            tags: tags,
            file,
            line
        )
    }
    
    ///
    open func warning(
        message: String,
        tags: [any LogTagging] = [],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .warning,
            message: message,
            error: nil,
            tags: tags,
            file,
            line
        )
    }
    
    ///
    open func error(
        message: String,
        error: Error?,
        tags: [any LogTagging] = [],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .error,
            message: message,
            error: error,
            tags: tags,
            file,
            line
        )
    }
    
    ///
    open func fatal(
        message: String,
        error: Error?,
        tags: [any LogTagging] = [],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .fatal,
            message: message,
            error: error,
            tags: tags,
            file,
            line
        )
    }
}
