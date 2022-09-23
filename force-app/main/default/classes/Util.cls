public class Util {

    // ------- Inner Classes ------
    public class DeveloperException extends Exception { private FINAL Boolean testCoverageTrick = FALSE; } // Exception representing a developer coding error, not intended for end user eyes

    public class TwoIdWrapper {
        private final Id FIRSTID {get; private set;}
        private final Id SECONDID {get; private set;}
        private final Set<Id> IDSET;
        private final String OUTSTRING;
        
        public TwoIdWrapper() { this(NULL, NULL); }
        
        public TwoIdWrapper(Id first_id, Id second_id) {
            FIRSTID = first_id;
            SECONDID = second_id;
            IDSET = new Set<Id>{FIRSTID, SECONDID};
            OUTSTRING = ((String)FIRSTID>(String)SECONDID) ? (SECONDID+'|'+FIRSTID) : (FIRSTID+'|'+SECONDID);
        }
        
        public Integer hashCode() {
            return System.hashCode(IDSET);
        }
        
        public Boolean equals(Object other) {
            TwoIdWrapper theOther = (TwoIdWrapper)other;
            return System.equals(IDSET, theOther.IDSET);
        }
    
        public Override String toString() { 
            return OUTSTRING;
        }
        
    }

}