package org.ekstep.ep.samza.external;

import java.util.Map;

public class ObjectResponse {
    public static final String SUCCESS_RESPONSE_STATUS = "successful";
    private String id;
    private String ver;
    private String ts;
    private Map<String, Object> params;
    public Result result;

    public boolean successful() {
        return params != null && SUCCESS_RESPONSE_STATUS.equals(params.get("status"));
    }

    public Map<String,Object> params() {
        return params;
    }

    public class Result {
        public Long objectId;

        @Override
        public String toString() {
            return "{" +
                    "objectId=" + objectId +
                    '}';
        }
    }

    @Override
    public String toString() {
        return "ObjectResponse{" +
                "id='" + id + '\'' +
                ", ver='" + ver + '\'' +
                ", ts='" + ts + '\'' +
                ", params=" + params +
                ", result=" + result +
                '}';
    }
}
