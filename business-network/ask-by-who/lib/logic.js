/**
 * Track the trade of a commodity from one trader to another
 * @param {org.example.mynetwork.Trade} trade - the trade to be processed
 * @transaction
 */
/*
async function tradeCommodity(trade) {
    trade.commodity.owner = trade.newOwner;
    let assetRegistry = await getAssetRegistry('org.example.mynetwork.Commodity');
    await assetRegistry.update(trade.commodity);
}
*/

const NS = 'org.example.mynetwork'

/**
 * Creates a new Surveyor participant
 * @param {org.example.mynetwork.CreateSurveyor} surveyor - the surveyor to be processed
 * @transaction
 */
async function createSurveyor(surveyor) {
  const surveyorRegistry = await getParticipantRegistry(`${NS}.Surveyor`)
    
  const { newResource } = getFactory()
    
  const newSurveyor = newRelationship(NS, 'Surveyor', surveyor.surveyorId)
  newSurveyor.firstName = surveyor.firstName
  newSurveyor.lastName = surveyor.lastName
  newSurveyor.organization = surveyor.organization
  
  await surveyorRegistry.add(newSurveyor)
}
  
/**
 * Create a new SurveySummary and assign it to a Supplier
 * @param {org.example.mynetwork.AddSurvey} survey - the survey to be processed
 * @transaction
 */
async function AddSurvey(survey) {
  const supplierRegistry = await getParticipantRegistry(`${NS}.Company`)
  
  // check whether or not the supplier exists before moving on.
  if (await supplierRegistry.exists(survey.supplierId)) {
    const surveyRegistry = await getAssetRegistry(`${NS}.SurveySummary`)
    const { newResource, newRelationship } = getFactory()

    // create a new SurveySummary asset
    const newSurvey = newResource(NS, 'SurveySummary', survey.surveyId)
    // make a pointer to Supplier instance based on the ID
    const supplierRelationship = newRelationship(NS, 'Company', survey.supplierId)
    // create a relationship between the survey and a supplier
    newSurvey.supplier = supplierRelationship
    // write in additional data
    newSurvey.summaryData = survey.summaryData
    newSurvey.createdAt = new Date()
    newSurvey.surveyor = survey.surveyor

    // add the new survey to the registry
    await surveyRegistry.add(newSurvey)
    

    const supplierPartnershipsQuery = await query(
      'selectPartnershipsBySupplier',
      { supplier: `resource:${NS}.Company#${survey.supplierId}` }
    )
    if (Array.isArray(supplierPartnershipsQuery)) {
      const partnershipRegistry = await getAssetRegistry(`${NS}.Partnership`)
     
      for (let partnership of supplierPartnershipsQuery) {
        const surveyRelationship = newRelationship(NS, 'SurveySummary', survey.surveyId)
        if ('surveys' in partnership) {
          partnership.surveys = partnership.surveys.concat(surveyRelationship)
        } else {
          partnership.surveys = [ surveyRelationship ]
        }
        await partnershipRegistry.update(partnership)
      }
    }
  } else {
  	throw new Error('No supplier found based on ID!')
  }
}

/**
 * Creates a partnership bond between brand and a supplier
 * @param {org.example.mynetwork.CreatePartnership} payload - contains supplier and brand instances
 * @transaction
 */
async function createPartnership({brand, supplier, partnershipId}) {
  const { newResource, newRelationship } = getFactory()
  const partnershipRegistry = await getAssetRegistry(`${NS}.Partnership`)
  const surveyRegistry = await getAssetRegistry(`${NS}.SurveySummary`)
  
  // TODO: there has to be better way to do this, right? RIGHT!?!
  const supplierActiveSurveyQuery = await query(
    'selectSurveysBySupplier', 
    { supplier: `resource:${NS}.Company#${supplier.supplierId}` }
  )

  if (supplierActiveSurveyQuery && Array.isArray(supplierActiveSurveyQuery)) {
    const newPartnership = newResource(NS, 'Partnership', partnershipId)
    // newPartnership.surveys = newRelationship(NS, 'SurveySummary', supplierActiveSurveyQuery[0].surveyId)
    newPartnership.brand = brand
    newPartnership.supplier = supplier
    newPartnership.createdAt = new Date()
    newPartnership.brandName = brand.companyName
    newPartnership.supplierName = supplier.companyName

    await partnershipRegistry.add(newPartnership) 
  } else {
  	throw new Error('The supplier does not have an active survey')
  }
}