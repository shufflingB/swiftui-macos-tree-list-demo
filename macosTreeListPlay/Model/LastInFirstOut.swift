//
//  LastInFirstOut.swift
//  macosTreeListPlayApp
//
//  Created by Jonathan Hume on 19/10/2022.
//

import Foundation

class LastInFirstOut<T: Equatable>: ObservableObject {
    @Published private(set) var firstOut: T? = nil
    private var array: Array<T> = []

    func push(ifNotFirstOut item: T) {
        if item != firstOut {
            push(item)
        }
    }

    func push(_ item: T) {
        array.append(item)
        firstOut = array.last
    }

    func pop() -> T? {
        let retVal: T? = array.isEmpty ? nil : array.removeLast()

        firstOut = array.isEmpty ? nil : array.last

        return retVal
    }
}
