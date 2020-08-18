package com.yourcompany.conferencedemo.controllers;


import com.yourcompany.conferencedemo.models.AttendeeSession;
import com.yourcompany.conferencedemo.repositories.AttendeeSessionRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/attendeeSessions")
public class AttendeeSessionController {

    private final AttendeeSessionRepository attendeeSessionRepository;

    public AttendeeSessionController(AttendeeSessionRepository attendeeSessionRepository) {
        this.attendeeSessionRepository = attendeeSessionRepository;
    }

    @GetMapping
    public List<AttendeeSession> getItems() {
        return this.attendeeSessionRepository.findAll();
    }
}
