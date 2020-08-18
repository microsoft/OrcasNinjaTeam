package com.yourcompany.conferencedemo.repositories;

import com.yourcompany.conferencedemo.models.Event;
import org.springframework.data.jpa.repository.JpaRepository;

// You could @RespositoryRestResource to expose this interface in a RESTful manner.
public interface EventRepository extends JpaRepository<Event, Long> {

}
