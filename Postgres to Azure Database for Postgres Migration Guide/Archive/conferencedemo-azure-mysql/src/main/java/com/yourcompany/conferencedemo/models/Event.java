package com.yourcompany.conferencedemo.models;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import java.util.Date;

// Name of the database table in Oracle.
@Entity(name="EVENTS")
public class Event {
    public Event() {}

    // You need to specify the identifier for this entity.
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Integer id;
    private String eventName;
    private String eventDescription;
    private Date eventEndDate;
    private Date eventStartDate;
    private Double eventPrice;
    private byte[] eventPic;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getEventName() {
        return eventName;
    }

    public void setEventName(String eventName) {
        this.eventName = eventName;
    }

    public String getEventDescription() {
        return eventDescription;
    }

    public void setEventDescription(String eventDescription) {
        this.eventDescription = eventDescription;
    }

    public Date getEventEndDate() {
        return eventEndDate;
    }

    public void setEventEndDate(Date eventEndDate) {
        this.eventEndDate = eventEndDate;
    }

    public Date getEventStartDate() {
        return eventStartDate;
    }

    public void setEventStartDate(Date eventStartDate) {
        this.eventStartDate = eventStartDate;
    }

    public Double getEventPrice() {
        return eventPrice;
    }

    public void setEventPrice(Double eventPrice) {
        this.eventPrice = eventPrice;
    }

    public byte[] getEventPic() {
        return eventPic;
    }

    public void setEventPic(byte[] eventPic) {
        this.eventPic = eventPic;
    }
}
