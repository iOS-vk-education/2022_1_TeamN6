//
//  EventModel.swift
//  NoCalendar
//
//  Created by Александр Клонов on 02.05.2022.
//

import Foundation

class EventModel {
    private var date: Date = Date()
    private var title: String = ""
    private var time: Date = Date()
    private var delta: Int64 = 0
    private var description: String = ""
    private var members: [String] = []
    
    let deltaDictionary: [String: Int64] = [
        "Никогда": 0,
        "Каждый час": 3600,
        "Каждый день": 86400,
        "Каждую неделю": 604800,
        "Каждый месяц": 86400 * 30
    ]
    
    func validateEvent(_ date: Date, _ title: String, _ time: String, _ delta: String, _ description: String, _ members: [String], okCallback: (() -> Void)?, failCallBack: ((newEventErrors) -> Void)?) {
        print("VALIDATE", date, time)
        if title == "" {
            failCallBack?(newEventErrors.noTitle)
        }
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "HH:mm"
        if dateFormatterGet.date(from: time) != nil && title != "" {
            self.saveData(date, title, time, delta, description, members)
            okCallback?()
        } else {
            failCallBack?(newEventErrors.noDate)
        }
    }
    
    func post(okCallback: (() -> Void)?, failCallBack: (() -> Void)?) {
        print(self.date, self.time)
        let hour = Calendar.current.component(.hour, from: self.time)
        let properDate = Calendar.current.date(byAdding: .hour, value: hour, to: self.date)
        var isRegular = false
        var delta: Int64? = nil
        if self.delta > 0 {
            isRegular = true
            delta = self.delta
        }
        let event = EventPost(title: self.title, description: self.description, timestamp: Int64(properDate!.timeIntervalSince1970), members: self.members, isRegular: isRegular, Delta: delta)
        print(event)
        
        NetworkModule.shared.postEvent(event: event, completion: { [] result in
            switch result {
            case .success(let answer):
                print(answer)
                DispatchQueue.main.async {
                    NetworkModule.shared.getAllEvents(completion: { [] result in
                        switch result {
                        case .success(let eventArray):
                            DatabaseModule.shared.saveEvents(events: eventArray)
                            DispatchQueue.main.async {
                                okCallback?()
                            }
                        case .failure(let error):
                            print("SAD :( ", error)
                        }
                    })
                    
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    let err = error as NSError
                    print(err.code)
//                    switch err.code {
//                    case self.codes.badRequest:
//                        failCallBack?(EventErrors.notAuthorised)
//                    default:
//                        failCallBack?(Event)
//                    }
                }
            }
        })
    }
    
    private func saveData(_ date: Date, _ title: String, _ time: String, _ delta: String, _ description: String, _ members: [String]) {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "HH:mm"
        
        self.date = date
        self.title = title
        self.time = dateFormatterGet.date(from: time)!
        self.delta = self.deltaDictionary[delta] ?? 0
        self.description = description
        self.members = members
    }
}
