Session        = require 'shared/services/session'
EventBus       = require 'shared/services/event_bus'
AbilityService = require 'shared/services/ability_service'
LmoUrlService  = require 'shared/services/lmo_url_service'
FlashService   = require 'shared/services/flash_service'
ModalService   = require 'shared/services/modal_service'

{ listenForTranslations, listenForReactions } = require 'shared/helpers/listen'

module.exports =
  props:
    event: Object
    eventable: Object
  created: ->
    @actions = [
      name: 'react'
      canPerform: => AbilityService.canAddComment(@eventable.discussion())
    ,
      name: 'reply_to_comment'
      icon: 'mdi-reply'
      canPerform: => AbilityService.canRespondToComment(@eventable)
      perform:    => EventBus.broadcast $rootScope, 'replyToEvent', @event.surfaceOrSelf(), @eventable
    ,
      name: 'edit_comment'
      icon: 'mdi-pencil'
      canPerform: => AbilityService.canEditComment(@eventable)
      perform:    => ModalService.open 'EditCommentForm', comment: => @eventable
    ,
      name: 'fork_comment'
      icon: 'mdi-call-split'
      canPerform: => AbilityService.canForkComment(@eventable)
      perform:    =>
        EventBus.broadcast $rootScope, 'toggleSidebar', false
        @event.toggleFromFork()
    ,
      name: 'translate_comment'
      icon: 'mdi-translate'
      canPerform: => @eventable.body && AbilityService.canTranslate(@eventable) && !@translation
      perform:    => @eventable.translate(Session.user().locale)
    ,
    #   name: 'copy_url'
    #   icon: 'mdi-link'
    #   canPerform: => clipboard.supported
    #   perform:    =>
    #     clipboard.copyText(LmoUrlService.event(@event, {}, absolute: true))
    #     FlashService.success("action_dock.comment_copied")
    # ,
      name: 'show_history'
      icon: 'mdi-history'
      canPerform: => @eventable.edited()
      perform:    => ModalService.open 'RevisionHistoryModal', model: => @eventable
    ,
      name: 'delete_comment'
      icon: 'mdi-delete'
      canPerform: => AbilityService.canDeleteComment(@eventable)
      perform:    => ModalService.open 'ConfirmModal', confirm: =>
        submit: @eventable.destroy
        text:
          title:    'delete_comment_dialog.title'
          helptext: 'delete_comment_dialog.question'
          confirm:  'delete_comment_dialog.confirm'
          flash:    'comment_form.messages.destroyed'
    ]
  # mounted: ->
  #   listenForReactions($scope, $scope.eventable)
  #   listenForTranslations($scope)
  template:
    """
    <div id="'comment-'+ eventable.id" class="new-comment">
      <div v-if="!eventable.translation" v-marked="eventable.cookedBody()" class="thread-item__body new-comment__body lmo-markdown-wrapper"></div>
      <translation v-if="eventable.translation" :model="eventable" field="body" class="thread-item__body"></translation>
      <!-- <outlet name="after-comment-body" model="eventable"></outlet> -->
      <document-list :model="eventable" :skip-fetch="true"></document-list>
      <div class="lmo-md-actions">
        <!-- <reactions_display model="eventable"></reactions_display> -->
        <action-dock :model="eventable" :actions="actions"></action-dock>
      </div>
      <!-- <outlet name="after-comment-event" model="eventable"></outlet> -->
    </div>
    """