//
//  BookProvider.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/20/26.
//


//
//  BookProvider.swift
//  Online Book Discovery System
//
//  Provider contract for all online book sources.
//  Providers must never throw and must always return
//  a valid array.
//

import Foundation

protocol BookProvider {
    func searchBooks(query: String) async -> [OnlineBook]
}

