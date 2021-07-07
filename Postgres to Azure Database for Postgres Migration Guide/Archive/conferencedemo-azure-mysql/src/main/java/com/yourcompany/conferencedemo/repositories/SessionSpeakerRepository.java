package com.yourcompany.conferencedemo.repositories;

import com.yourcompany.conferencedemo.models.SessionSpeaker;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SessionSpeakerRepository extends JpaRepository<SessionSpeaker, Integer> {
    List<SessionSpeaker> findByEventId(Integer eventId);
}
