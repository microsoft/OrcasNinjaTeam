package com.yourcompany.conferencedemo.controllers;


import com.yourcompany.conferencedemo.models.Attendee;
import com.yourcompany.conferencedemo.repositories.AttendeeRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/attendees")
public class AttendeeController  {

    private final AttendeeRepository attendeeRepository;

    public AttendeeController(AttendeeRepository attendeeRepository) {
        this.attendeeRepository = attendeeRepository;
    }


    @GetMapping
    public List<Attendee> getAttendees() {
        return attendeeRepository.findAll();
    }

    @GetMapping("/randomAttendee")
    public Attendee getRandomAttendInfo () {
        Long attendeeId =  attendeeRepository.getRandomAttendee();
        return this.attendeeRepository.findById(attendeeId).orElseThrow();
    }


    @GetMapping("/{id}")
    public Attendee getAttendee(@PathVariable Long id) {
        return this.attendeeRepository.findById(id).orElseThrow();
    }
}
