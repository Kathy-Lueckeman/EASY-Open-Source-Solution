// DEPRECATED
trigger UserApplicationTrigger on User (before insert) {
    System.debug('DEPRECATED: UserApplicationTrigger');
}