App.WizardStepView = Em.View.extend({
    templateName: 'wizardstep',
    atStep: null,
    stepsTotal: null,
    actions: {
        goBack: function(){
            window.history.back();
        }
    },
    isFirstStep: function(){
        var step = this.get('atStep');
        return _.isNumber(step) && step == 1;
    }.property('atStep'),
    isLastStep: function(){
        var curStep = this.get('atStep'),
            stepsTotal = this.get('stepsTotal');
        return _.isNumber(curStep) && _.isNumber(stepsTotal) && stepsTotal == curStep;
    }.property('atStep')
});