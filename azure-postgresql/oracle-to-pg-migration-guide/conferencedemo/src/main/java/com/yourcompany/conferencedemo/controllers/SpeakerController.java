package com.yourcompany.conferencedemo.controllers;


import com.yourcompany.conferencedemo.models.Speaker;
import com.yourcompany.conferencedemo.repositories.SpeakerRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/speakers")
public class SpeakerController {

    private final SpeakerRepository speakerRepository;

    public SpeakerController(SpeakerRepository speakerRepository) {

        this.speakerRepository = speakerRepository;
    }

    @GetMapping
    public List<Speaker> getSpeakers() {
        return speakerRepository.findAll();
    }


    @GetMapping("/{id}")
    public Speaker getSpeaker(@PathVariable Long id) {
        return speakerRepository.findById(id).orElseThrow();
    }
}
