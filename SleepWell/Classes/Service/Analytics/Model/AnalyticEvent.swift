//
//  AnalyticEvent.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 27/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

enum AnalyticEvent {
    case welcomeScr
    case welcomePaygateScr
    case helpYouWithScr
    case genderAngAgeScr
    case bedtimeScr
    case slideScr
    
    case sceneScr
    case sceneSettingsScr
    case scenePlayPauseTap
    case sceneRandomTap
    case sceneDefaultTap
    case sceneSleepTimerTap
    case sceneSleepTimerSet
    case blockedScenePaygateScr
    
    case storiesScr
    case playRandomStoryTap
    case blockedRandomStoryPaygateScr
    case blockedStoryPaygateScr
    case unlockPremiumStoriesPaygateScr
    
    case meditateScr
    case tagTap
    case blockedMeditationPaygateScr
    case unlockPremiumMeditationsPaygateScr
    
    case settingsScr
    
    case searcgAdsClickAd
}

extension AnalyticEvent {
    var name: String {
        switch self {
        case .welcomeScr:
            return "Welcome scr"
        case .welcomePaygateScr:
            return "Welcome paygate scr"
        case .helpYouWithScr:
            return "Help you with scr"
        case .genderAngAgeScr:
            return "Gender and age scr"
        case .bedtimeScr:
            return "Bedtime scr"
        case .slideScr:
            return "Slide scr"
            
        case .sceneScr:
            return "Scene scr"
        case .sceneSettingsScr:
            return "Scene settings scr"
        case .scenePlayPauseTap:
            return "Scene play/pause tap"
        case .sceneRandomTap:
            return "Scene random tap"
        case .sceneDefaultTap:
            return "Scene default tap"
        case .sceneSleepTimerTap:
            return "Scene sleep timer tap"
        case .sceneSleepTimerSet:
            return "Scene sleep timer set"
        case .blockedScenePaygateScr:
            return "Blocked scene paygate scr"
            
        case .storiesScr:
            return "Stories scr"
        case .playRandomStoryTap:
            return "Play random story tap"
        case .blockedRandomStoryPaygateScr:
            return "Blocked random story paygate scr"
        case .blockedStoryPaygateScr:
            return "Blocked story paygate scr"
        case .unlockPremiumStoriesPaygateScr:
            return "Unlock premium stories paygate scr"
            
        case .meditateScr:
            return "Meditate scr"
        case .tagTap:
            return "Tag tap"
        case .blockedMeditationPaygateScr:
            return "Blocked meditation paygate scr"
        case .unlockPremiumMeditationsPaygateScr:
            return "Unlock premium meditations paygate scr"
            
        case .settingsScr:
            return "Settings scr"
            
        case .searcgAdsClickAd:
            return "SearchAds Ad Click"
        }
    }
}
