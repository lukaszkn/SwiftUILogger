import SwiftUI

struct LogEventView: View {
    typealias Event = SwiftUILogger.Event

    let event: Event
    let isMinimal: Bool

    var body: some View {
        if isMinimal {
            HStack {
                let dateTime = Event.dateTimeFormatter.string(from: event.dateCreated)
                Text("\(dateTime) \(event.level.emoji.description): \(event.message)")
                    .font(.footnote)
                Spacer()
            }
            .frame(
                maxWidth: .infinity
            )
        } else {
            VStack {
                HStack(spacing: 8) {
                    Text(event.dateCreated, formatter: Event.dateFormatter)
                        .font(.callout)
                    Text("@")
                    Text(event.dateCreated, formatter: Event.timeFormatter)
                        .font(.callout)
                    Spacer()
                    if event.error != nil {
                        Text("🚨")
                    }
                }

                Divider()

                Text("\(event.metadata.file.description)@\(event.metadata.line)")
                    .font(.callout)

                Divider()

                Text(event.message)
                    .font(.body)

                if let error = event.error {
                    Divider()
                    Text(error.localizedDescription)
                }
            }
            .padding(.horizontal, 8)
            .frame(
                maxWidth: .infinity
            )
            .padding(.vertical)
            .border(event.level.color, width: 4)
            .cornerRadius(4)
        }
    }
}
