import PopoverIcon from 'playful/components/popover-icon';

export default PopoverIcon.extend({
  tagName: 'button',
  classNames: "btn btn-default",
  attributeBindings: ['disabled'],
  popoverAttachment: function(){
    return this.$();
  }.property('iconType')
});
