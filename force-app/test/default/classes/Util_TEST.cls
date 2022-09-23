@isTest
public class Util_TEST {
    
    static testMethod void testDeveloperException() {
        try {
            throw new Util.DeveloperException('Hi there');
        }
        catch(Util.DeveloperException e) {
            System.assertEquals('Hi there', e.getMessage());
        }
    }

    static testMethod void testTwoIdWrapper() {
        Id pId = userinfo.getProfileId();
        Id uId = userinfo.getOrganizationId();
        Id oId = userinfo.getUserId();
        
        Util.TwoIdWrapper puWrap = new Util.TwoIdWrapper(pId, uId);
        Util.TwoIdWrapper puWrapDupl = new Util.TwoIdWrapper(pId, uId);
        Util.TwoIdWrapper upWrap = new Util.TwoIdWrapper(uId, pId);
        Util.TwoIdWrapper poWrap = new Util.TwoIdWrapper(pId, oId);
        
        System.assertEquals(puWrap, puWrapDupl, 'pu and pudupl wraps failed to match');
        System.assertEquals(puWrap, upWrap, 'pu and up wraps failed to match');
        System.assertNotEquals(puWrap, poWrap, 'pu and po matched but should not');
        
        Set<Util.TwoIdWrapper> puWrapPuWrapDuplSet = new Set<Util.TwoIdWrapper>{puWrap, puWrapDupl};
        Set<Util.TwoIdWrapper> puWrapUpWrapSet = new Set<Util.TwoIdWrapper>{puWrap, upWrap};
        Set<Util.TwoIdWrapper> puWrapPoWrapSet = new Set<Util.TwoIdWrapper>{puWrap, poWrap};
        System.assertEquals(1, puWrapPuWrapDuplSet.size(), 'pu and pudupl wraps failed to match in set');
        System.assertEquals(1, puWrapUpWrapSet.size(), 'pu and up wraps failed to match in set');
        System.assertEquals(2, puWrapPoWrapSet.size(), 'pu and op wraps failed set size 2');

        System.assertEquals(puWrap.toString(), puWrapDupl.toString(), 'toString error - puduplWrap');
        System.assertEquals(puWrap.toString(), upWrap.toString(), 'toString error - upWrap');
        System.assertNotEquals(puWrap.toString(), poWrap.toString(), 'toString error - poWrap');
    }
    
}