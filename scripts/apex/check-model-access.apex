// Checks whether this org can call the model Agent Optimizer (Beta) reasons with.
// Run:  sf apex run --file scripts/apex/check-model-access.apex
//
//   Sonnet answers, Opus answers      -> the org can run Agent Optimizer.
//   Sonnet answers, Opus refused 429  -> the org's limit for advanced models is
//                                         zero (seen with org_status Free and Trial).
//                                         No setting in the org changes it.
//   Sonnet refused too                -> a setup problem, not the model gate.
aiplatform.ModelsAPI api = new aiplatform.ModelsAPI();
for (String m : new List<String>{
        'sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet', // control
        'sfdc_ai__DefaultBedrockAnthropicClaude48Opus'}) { // Optimizer's model
    aiplatform.ModelsAPI.createGenerations_Request req =
        new aiplatform.ModelsAPI.createGenerations_Request();
    req.modelName = m;
    aiplatform.ModelsAPI_GenerationRequest body = new aiplatform.ModelsAPI_GenerationRequest();
    body.prompt = 'Reply with the single word OK.';
    req.body = body;
    try {
        System.debug(m + ' => ' + api.createGenerations(req).Code200.generation.generatedText);
    } catch (aiplatform.ModelsAPI.createGenerations_ResponseException e) {
        System.debug(m + ' => refused ' + e.responseCode + ': ' + e.Code429);
    }
}
