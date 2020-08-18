package com.yourcompany.conferencedemo.controllers;


import com.yourcompany.conferencedemo.models.SessionSpeaker;
import com.yourcompany.conferencedemo.repositories.SessionSpeakerRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/sessionSpeakers")
public class SessionSpeakerController {

    private final SessionSpeakerRepository sessionSpeakerRepository;

    public SessionSpeakerController(SessionSpeakerRepository sessionSpeakerRepository) {
        this.sessionSpeakerRepository = sessionSpeakerRepository;
    }

    @GetMapping("/{eventId}")
    public List<SessionSpeaker> getSessionSpeaker(@PathVariable("eventId") Long eventId) {
        return this.sessionSpeakerRepository.findByEventId(eventId);
    }
}
