package org.ekstep.ep.samza.system;

import org.ekstep.ep.samza.service.ContentService;
import org.ekstep.ep.samza.domain.Event;
import org.ekstep.ep.samza.search.domain.Content;

import java.io.IOException;

public class ContentDeNormStrategy implements Strategy {
    private final ContentService contentService;

    public ContentDeNormStrategy(ContentService contentService) {
        this.contentService = contentService;
    }

    @Override
    public void execute(Event event) throws IOException {
        Content content = contentService.getContent(event.id(), event.getObjectID());
        if(content != null){
            event.updateContent(content);
        }
    }
}
