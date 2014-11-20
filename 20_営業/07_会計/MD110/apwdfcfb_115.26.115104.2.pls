REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \ 
REM dbdrv: checkfile:~PROD:~PATH:~FILE 

REM +==================================================================+
REM |                Copyright (c) 1997 Oracle Corporation
REM |                   Redwood Shores, California, USA
REM |                        All rights reserved.
REM +==================================================================+
REM |  Name
REM |    apwdfcfb.pls
REM |
REM |  Description
REM |    Custom flexfield routines
REM |
REM |  History
REM |    01-JUL-97 skaneshi/hchung  created
REM |
REM +==================================================================+
 
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
 
CREATE OR REPLACE PACKAGE BODY AP_WEB_CUST_DFLEX_PKG AS
/* $Header: apwdfcfb.pls 115.26.115104.2 2008/09/23 14:01:46 rveliche ship $ */


----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- CUSTOMPOPULATEPOPLIST:  This procedure provides a way to populate
--    the values for custom fields rendered as poplists.  This is pertinent
--    only for segments which have value sets which have independent and table
--    validation types.  If longlist enabled is checked for the segment, the
--    segment is rendered as a text item, and this routine is not called.
--
--    For segments with the independent validation type:
--      (1) If CustomPopulatePoplist returns values, those values are used
--          in the poplist.
--      (2) Otherwise, the values defined for the independent value set is
--          is used.
--      (3) Otherwise, the segment is rendered as a text item.
--
--    For segments with table validation type:
--      (1) If CustomPopulatePoplist returns values, those values are used
--          in the poplist.  Since this release does not execute the query
--          statement, you will have to reenter the query here.
--      (2) Otherwise, the segment is rendered as a text item.
--    
-- PARAMETERS:
--
--   P_ExpReportHeaderInfo - Contains header information about the 
--                           expense report.
--   P_ExpenseTypeName - Expense type string, corresponds to the Context
--                       Field Value Name field on the Descriptive 
--                       Flexfield Segments 10SC form.
--   P_CustomFieldName - Custom field name, corresponds to the name of the
--                       segment on the Segment Summary 10SC form.
--   P_NumOfPoplistElem - Number of elements returned in the P_PoplistArray
--   P_PoplistArray - Array containing the values to be put into the poplist.
--                    For each element, specify an InternalValue which will
--                    actually be validated and saved, and a DisplayText
--                    which will be displayed in the poplist.
--                    Array is 1-based (array index should should start with 1)
--
----------------------------------------------------------------------------
----------------------------------------------------------------------------
PROCEDURE CustomPopulatePoplist(
             P_ExpenseTypeName     IN  VARCHAR2,
             P_CustomFieldName     IN  VARCHAR2,
             P_NumOfPoplistElem    OUT NOCOPY NUMBER,
             P_PoplistArray        OUT NOCOPY AP_WEB_DFLEX_PKG.PoplistValues_A)
------------------------------------------------------------------------
IS
  V_CurrentCallingSequence   VARCHAR2(240);
  V_DebugInfo                VARCHAR2(240);
BEGIN

  V_CurrentCallingSequence := 'AP_WEB_CUST_DFLEX_PKG.CustomPopulatePoplist';

  V_DebugInfo := 'No poplist values provided.';
  P_NumOfPoplistElem := 0;

  --
  -- Insert logic to populate poplist elements here
  -- Example:
  --
  --  IF (UPPER(P_ExpenseTypeName) = 'CAR RENTAL') THEN
  --
  --    IF (UPPER(P_CustomFieldName) = 'RENTAL AGENCY') THEN
  --     
  --      P_PoplistArray(1).InternalValue := 'Hertz';
  --      P_PoplistArray(1).DisplayText := 'Hertz Custom Test';
  --
  --      P_PoplistArray(2).InternalValue := 'Avis';
  --      P_PoplistArray(2).DisplayText := 'Avis Custom Test';
  --
  --      P_NumOfPoplistElem := 2;
  --
  --    END IF;
  --
  --  ELSIF (UPPER(P_ExpenseTypeName) = 'GLOBAL DATA ELEMENTS') THEN
  -- 
  --    IF (UPPER(P_CustomFieldName) = 'TEST PROMPT') THEN
  --
  --      ...
  --
  --    END IF;
  -- 
  --  END IF;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
    FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
    FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                          V_CurrentCallingSequence);
    FND_MESSAGE.SET_TOKEN('DEBUG_INFO',V_DebugInfo);
    AP_WEB_UTILITIES_PKG.DisplayException(fnd_message.get);
END CustomPopulatePoplist;

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- CUSTOMPOPULATEDEFAULT:  This procedure provides a way to
--    implement complex defaulting logic for the descriptive flexfield
--    custom fields you have defined other than what you have provided
--    for the descriptive flexfield definition.  If no default is returned
--    by this routine, then the default value taken from the default
--    value field in the Segment 10SC form.
--
--    It is not possible to customize segments in the "Global Data Elements",
--    only the ones in the custom context values (expense types).
--
--    For checkboxes, specify 'Y' for check and 'N' to leave the box 
--    unchecked.
-- 
-- PARAMETERS:
--
--   P_ExpReportHeaderInfo - Contains header information about the 
--                           expense report.
--   P_ExpenseTypeName - Expense type string, corresponds to the Context
--                       Field Value Name field on the Descriptive 
--                       Flexfield Segments 10SC form.
--   P_CustomFieldName - Custom field name, corresponds to the name of the
--                       segment on the Segment Summary 10SC form.
--   P_DefaultValue - Custom default value.
-- 
----------------------------------------------------------------------------
----------------------------------------------------------------------------
PROCEDURE CustomPopulateDefault(
             P_ExpenseTypeName     IN  VARCHAR2,
             P_CustomFieldName     IN  VARCHAR2,
             P_DefaultValue        OUT NOCOPY VARCHAR2)
------------------------------------------------------------------
IS
  V_CurrentCallingSequence   VARCHAR2(240);
  V_DebugInfo                VARCHAR2(240);
BEGIN

  V_CurrentCallingSequence := 'AP_WEB_CUST_DFLEX_PKG.CustomPopulateDefault';

  V_DebugInfo := 'No default values provided.';
  P_DefaultValue := '';

  --
  -- Insert logic to calculate the default
  -- Example:
  -- 
  --   IF (UPPER(P_ExpenseTypeName) = 'GLOBAL DATA ELEMENTS') THEN
  -- 
  --     IF (UPPER(P_CustomFieldName) = 'TEST PROMPT') THEN
  --       P_DefaultValue := 'Custom Test';
  --     END IF;
  -- 
  --   ELSIF (UPPER(P_ExpenseTypeName) = 'AIRFARE') THEN
  -- 
  --     IF (UPPER(P_CustomFieldName) = 'AIRLINE') THEN
  --       P_DefaultValue := 'United';
  --     END IF;
  -- 
  --   ELSIF (UPPER(P_ExpenseTypeName) = 'HOTEL') THEN
  -- 
  --     IF (UPPER(P_CustomFieldName) = 'NEGOTIATED RATE USED?') THEN
  --      
  --       P_DefaultValue := 'Y';
  --     END IF;
  -- 
  --   ELSIF (UPPER(P_ExpenseTypeName) = 'CAR RENTAL') THEN
  -- 
  --     IF (UPPER(P_CustomFieldName) = 'RENTAL AGENCY') THEN
  --      
  --       P_DefaultValue := 'Hertz';
  --     END IF;
  -- 
  --   END IF;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
    FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
    FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                          V_CurrentCallingSequence);
    FND_MESSAGE.SET_TOKEN('DEBUG_INFO',V_DebugInfo);
    AP_WEB_UTILITIES_PKG.DisplayException(fnd_message.get);
END CustomPopulateDefault;


-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
--  CUSTOMVALIDATEDFLEXVALUES:  This procedure provides you a way to
--    implement any special custom validation logic besides the basic
--    descriptive flexfield value set validation you wish to perform
--    on the descriptive flexfield custom flexfields you have defined.
--    Both individual custom field value validation logic as well as 
--    cross custom field value validation, i.e. custom fields that are 
--    context-sensitive to values of other custom fields, belong here.  
--    We have also provided a function GetCustomFieldValue for which you 
--    provide the name of the custom field and the custom_fields_array and 
--    the custom field value is returned.  This function makes accessing
--    the values of custom fields other than the current custom field being 
--    processed possible.  The following is that function spec:
--
--      FUNCTION GetCustomFieldValue(p_prompt			IN VARCHAR2,
--          p_custom_fields_array	IN CustomFields_A) RETURN VARCHAR2);
--
--
--
--  PARAMETERS:
--
--    p_exp_header_info - record that contains expense report header
--                        information.  The record contains the following
--                        components:
--    			    report_header_id	NUMBER,
--			    employee_id		VARCHAR2(25),
--			    cost_center		VARCHAR2(30),
--			    template_id		VARCHAR2(25),
--			    template_name	VARCHAR2(100),
--			    purpose		VARCHAR2(240),
--    			    summary_start_date	VARCHAR2(25),
--    			    summary_end_date	VARCHAR2(25),
--    			    summary_xtype	VARCHAR2(25),
--    			    receipt_index	NUMBER,
--    			    last_receipt_date	VARCHAR2(25),
--    			    last_update_date	VARCHAR2(25),
--			    receipt_count	VARCHAR2(25),
--			    transaction_currency_type	VARCHAR2(25),
--			    reimbursement_currency_code	VARCHAR2(25),
--			    reimbursement_currency_name	VARCHAR2(80),
--			    multi_currency_flag	VARCHAR2(1),
--			    inverse_rate_flag	VARCHAR2(1),
--			    override_approver_id	VARCHAR2(25),
--			    override_approver_name	VARCHAR2(80)
--			    expenditure_organization_id NUMBER(15),
--			    number_max_flexfield	NUMBER,
--			    amt_due_employee		NUMBER,
--			    amt_due_ccCompany		NUMBER); 
--
--                       Usage:  p_exp_header_info.multi_currency_flag 
--
--    p_exp_line_info   - record that contains expense report line
--                        information.  The record contains the following
--			  components:
--			    receipt_index       NUMBER, -- index of receipt starting from 1
--  			    start_date		DATE,
--			    end_date		DATE,
--			    days		VARCHAR2(25),
--			    daily_amount	VARCHAR2(25),
--			    receipt_amount	VARCHAR2(50),
--			    rate		VARCHAR2(25),
--			    amount		VARCHAR2(50),
--			    parameter_id	VARCHAR2(25),
--			    expense_type	VARCHAR2(80),
--			    currency_code	VARCHAR2(25),
--			    cCardTrxnId         NUMBER,
--			    category            VARCHAR2(30),
--			    group_value		VARCHAR2(80),
--			    justification	VARCHAR2(240),
--			    receipt_missing_flag VARCHAR2(1),
--			    validation_required	 VARCHAR2(1),
--			    calculate_flag	 VARCHAR2(1),
--			    calculated_amount	 VARCHAR2(50),
--			    copy_calc_amt_into_receipt_amt VARCHAR2(1)
--			    amount_includes_tax  VARCHAR2(1),
--			    tax_code             VARCHAR2(15),
--			    taxOverrideFlag	 VARCHAR2(1),
--			    taxId		 VARCHAR2(15),
--			    project_id           VARCHAR2(15),
--			    project_number       VARCHAR2(25),
--			    task_id              VARCHAR2(15),
--			    task_number          VARCHAR2(25),
--			    expenditure_type     VARCHAR2(30)
--
--                       Usage:  p_exp_line_info.expense_type
--
--    p_custom_fields_array  - array of custom fields record required by
--                             GetCustomFieldValue function as a parameter  
--                             Needed for inter-dependent custom field 
--                             validation
--
--    p_custom_field_record - record containing custom field information
--                            of the custom field being validated.
--
--    p_validation_level - validation level at which this api is being
--                         called.
--
--    p_resulting_message - available for you to assign any validation error
--                          or warning message to be displayed to the user.
--
--    p_message_type - (used in the future, not currently supported)
--		       if p_resulting_message is an error message, 
--                       then set p_message_type = 'ERROR'
--                     if p_resulting_message is a warning message,
--                       then set p_message_type = 'WARNING'
--                     You can refer to the following predefined constants 
--                       in your code:
--                       AP_WEB_DFLEX_PKG.C_CustValidResMsgTypeNone
--                       AP_WEB_DFLEX_PKG.C_CustValidResMsgTypeError
--                       AP_WEB_DFLEX_PKG.C_CustValidResMsgTypeWarning
--
---------------------------------------------------------------------------
---------------------------------------------------------------------------
PROCEDURE CustomValidateDFlexValues(
	p_exp_header_info	IN AP_WEB_DFLEX_PKG.ExpReportHeaderRec,
	p_exp_line_info		IN AP_WEB_DFLEX_PKG.ExpReportLineRec,
	p_custom_fields_array	IN AP_WEB_DFLEX_PKG.CustomFields_A,
	p_custom_field_record  	IN AP_WEB_DFLEX_PKG.CustomFieldRec,
	p_validation_level	IN VARCHAR2,
	p_result_message 	IN OUT NOCOPY VARCHAR2,
	p_message_type  	IN OUT NOCOPY VARCHAR2,
	p_receipt_index		IN BINARY_INTEGER)
---------------------------------------------------------------------------
IS
  l_debug_info			VARCHAR2(2000);
  l_curr_calling_sequence	VARCHAR2(200) := 'CustomValidateDFlexValues';
BEGIN

  IF (p_validation_level = 'HEADER') THEN

    ------------------------------------------------------------------
    -- Expense Report Header Level Validation Logic Goes Here
    -- Currently not supported.  Feature to be implemented later on.
    ------------------------------------------------------------------
    NULL;

  ELSIF (p_validation_level = 'LINE') THEN

    --------------------------------------------------------
    -- Expense Report Lines Level Validation Logic Goes Here
    --------------------------------------------------------
    NULL;

  ELSIF (p_validation_level = 'FIELD') THEN

    -------------------------------------------------------------------
    -- Expense Report Type-Related Level Validation Logic Goes Here
    -- EXAMPLE CODE:
    -- IF (upper(p_custom_field_record.prompt) = 'RATE PER MILE') THEN
    --
    --   IF (p_custom_field_record.value > 5) THEN
    --
    --     p_result_message := 'Rate per mile cannot exceed 5';
    --     p_message_type := 'ERROR';
    --     return;
    --   END IF;
    -- ELSE IF (upper(p_custom_field_record.prompt) = '...') THEN
    --
    -- ELSE IF ... THEN
    --
    -- END IF;
    -------------------------------------------------------------------

    NULL;

  END IF;

EXCEPTION
  WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                    l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
        AP_WEB_UTILITIES_PKG.DisplayException(fnd_message.get);
END CustomValidateDFlexValues;


----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- CUSTOMCALCULATEAMOUNT:  This procedure is here to implement the
--    calculate amount feature to provide you a mechanism to perform
--    custom expense line calculation based off of expense report header,
--    line and custom field values.
--
-- PARAMETERS:
--
--    p_exp_header_info - record that contains expense report header
--                        information.  The record contains the following
--                        components:
--			    employee_id		VARCHAR2(25),
--			    cost_center		VARCHAR2(30),
--			    template_id		VARCHAR2(25),
--			    template_name	VARCHAR2(100),
--			    purpose		VARCHAR2(240),
--			    last_receipt_date	VARCHAR2(25),
--			    receipt_count	VARCHAR2(25),
--			    transaction_currency_type	VARCHAR2(25),
--			    reimbursement_currency_code	VARCHAR2(25),
--			    reimbursement_currency_name	VARCHAR2(80),
--			    multi_currency_flag	VARCHAR2(1),
--			    inverse_rate_flag	VARCHAR2(1),
--			    override_approver_id		VARCHAR2(25),
--			    override_approver_name	VARCHAR2(80)
--
--                       Usage:  p_exp_header_info.multi_currency_flag 
--
--    p_exp_line_info - record that contains expense report line
--                      information.  The record contains the following
--			components:
--  			    start_date		date,
--			    end_date		date,
--			    days		VARCHAR2(25),
--			    daily_amount	VARCHAR2(25),
--			    receipt_amount	VARCHAR2(50),
--			    rate		VARCHAR2(25),
--			    amount		VARCHAR2(50),
--			    parameter_id	VARCHAR2(25),
--			    expense_type	VARCHAR2(80),
--			    currency_code	VARCHAR2(25),
--			    group_value		VARCHAR2(80),
--			    justification	VARCHAR2(240),
--			    receipt_missing_flag VARCHAR2(1),
--			    validation_required	 VARCHAR2(1),
--			    calculate_flag	 VARCHAR2(1),
--			    calculated_amount	 VARCHAR2(50),
--			    copy_calc_amt_into_receipt_amt	VARCHAR2(1)
--
--                       Usage:  p_exp_line_info.expense_type
--
--    All the components of p_exp_line_info are reference information
--    except for the last 2 components:
--
--      The result of the calculated_amount needs to be assigned into 
--      p_exp_line_info.calculated_amount 
--
--      For foreign currency, you can also specify if you want the result
--      copied into the Receipt Amount instead of Total.  Total is the
--      expense line amount in the reimbursement currency while
--      Receipt Amount is without the foreing currency conversion.  If
--      you want to let the end-user specify the currency rate, set
--      p_exp_line_info.copy_calc_amt_into_receipt_amt := 'Y'.    
--
--    p_custom_fields_array - array of custom fields record required by
--                            the GetCustomFieldValue function as a parameter
--                            Needed for inter-dependent custom field 
--                            validation
-- 
--    Currently we only support propogating the calculated result back
--    to either the 'Total' field or the 'Receipt Amount' field in the
--    Enter Receipts page.  By default, it is the 'Total' field, but for 
--    the case where the reimbursement currency is different from the receipt
--    currency, if you want to allow the user to specify the conversion
--    rate from receipt currency to reimbursement currency, you can
--    specify that the amount calculated is to be copied into the
--    'Receipt Amount' field by setting:
--            p_exp_line_info.copy_calc_amt_into_receipt_amt := 'Y';
--    otherwise it will be copied into the 'Total' field.  Setting this
--    flag only works when reimbursement currency is different from
--    receipt currency.
----------------------------------------------------------------------------
----------------------------------------------------------------------------
PROCEDURE CustomCalculateAmount(
	p_exp_header_info	IN OUT NOCOPY AP_WEB_DFLEX_PKG.ExpReportHeaderRec, -- epxense report header details
	p_exp_line_info		IN OUT NOCOPY AP_WEB_DFLEX_PKG.ExpReportLineRec, -- expense report line detail
	p_custom_fields_array	IN AP_WEB_DFLEX_PKG.CustomFields_A, -- custom field details
	-- p_addon_rates used for mileage category only
	p_addon_rates           IN OIE_ADDON_RATES_T, -- array of additional rate types
        p_report_line_id        IN NUMBER DEFAULT NULL, -- report line id
        -- below fields are used for per diem category only
        p_daily_breakup_id              IN      OIE_PDM_NUMBER_T DEFAULT NULL, -- array of unique identifer for daily breakups
        p_start_date                    IN      OIE_PDM_DATE_T DEFAULT NULL, -- array of start date
        p_end_date                      IN      OIE_PDM_DATE_T DEFAULT NULL,-- array of end date
        p_amount                        IN      OIE_PDM_NUMBER_T DEFAULT NULL,-- array of amount
        p_number_of_meals               IN      OIE_PDM_NUMBER_T DEFAULT NULL,-- array of number of meals
        p_meals_amount                  IN      OIE_PDM_NUMBER_T DEFAULT NULL,-- array of meals amount
        p_breakfast_flag                IN      OIE_PDM_VARCHAR_1_T DEFAULT NULL,-- array of breakfast flag
        p_lunch_flag                    IN      OIE_PDM_VARCHAR_1_T DEFAULT NULL, -- array of lunch flag
        p_dinner_flag                   IN      OIE_PDM_VARCHAR_1_T DEFAULT NULL, -- array of dinner flag
        p_accommodation_amount          IN      OIE_PDM_NUMBER_T DEFAULT NULL, -- array of accommodation amount
        p_accommodation_flag            IN      OIE_PDM_VARCHAR_1_T DEFAULT NULL, -- array of accommodation flag
        p_hotel_name                    IN      OIE_PDM_VARCHAR_80_T DEFAULT NULL, -- array of hotel name
        p_night_rate_Type               IN      OIE_PDM_VARCHAR_80_T DEFAULT NULL, -- array of night rate type
        p_night_rate_amount             IN      OIE_PDM_NUMBER_T DEFAULT NULL, -- array of night rate amount
        p_pdm_rate                      IN      OIE_PDM_NUMBER_T DEFAULT NULL, -- array of pdm rate
        p_rate_Type_code                IN      OIE_PDM_VARCHAR_80_T DEFAULT NULL, -- array of rate type code
        p_pdm_breakup_dest_id           IN      OIE_PDM_NUMBER_T DEFAULT NULL, -- array of unique identified for multiple destinations
        p_pdm_destination_id            IN      OIE_PDM_NUMBER_T DEFAULT NULL, -- array of locations for each breakup period
        p_dest_start_date               IN      OIE_PDM_DATE_T DEFAULT NULL, -- array of start date for each location
        p_dest_end_date                 IN      OIE_PDM_DATE_T DEFAULT NULL,-- array of end date for each location
        p_location_id                   IN      OIE_PDM_NUMBER_T DEFAULT NULL, -- array of locations
        -- bug 5358186
        p_cust_meals_amount             IN OUT  NOCOPY OIE_PDM_NUMBER_T, -- array of modified meals amount
        p_cust_accommodation_amount     IN OUT  NOCOPY OIE_PDM_NUMBER_T,-- array of modified accommodation amount
        p_cust_night_rate_amount        IN OUT  NOCOPY OIE_PDM_NUMBER_T,-- array of modified night rate amount
        p_cust_pdm_rate                 IN OUT  NOCOPY OIE_PDM_NUMBER_T-- array of modified pdm rate
        )
---------------------------------------------------------------------------
IS
  l_miles			NUMBER;
  l_rate_per_mile	NUMBER;
  l_debug_info		VARCHAR2(2000);
  l_curr_calling_sequence	VARCHAR2(200) := 'CustomCalculateAmount';
  i number ;
  l_hours number ;
  l_tot_amount number := 0;
  l_amount number := 0;
  l_date1 date := null;
  l_date2 date := null;
  --  l_addon_array     OIE_ADDON_RATES_T;
  
BEGIN
  ------------------------------------------------------------------------
  l_debug_info := 'Expense type ='|| p_exp_line_info.expense_type;
  AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_CUST_DFLEX_PKG', l_debug_info);
  ------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  -- Example code:  Mileage
  --
  --   IF (upper(p_exp_line_info.expense_type) = 'MILEAGE') THEN
  --
  --     l_miles := AP_WEB_DFLEX_PKG.GetCustomFieldValue('MILES', p_custom_fields_array);
  --     l_rate_per_mile := AP_WEB_DFLEX_PKG.GetCustomFieldValue('RATE PER MILE', p_custom_fields_array);
  --     p_exp_line_info.calculated_amount := l_miles * l_rate_per_mile;
  --     p_exp_line_info.copy_calc_amt_into_receipt_amt := 'Y';
  --  
  --   ELSE IF (upper(p_exp_line_info.expense_type) = 'PER DIEM') THEN
  --
  --     NULL;
  --
  --   ELSE IF ...
  --
  --   END IF;
  ----------------------------------------------------------------------------
  IF (upper(p_exp_line_info.expense_type) = 'MILEAGE') THEN
      NULL;
  END IF;
  
  /* Below sample code is part of a white paper which is to be published on client extension.*/
  /*
  -- sample code for expense type 'Mileage Client Extension Test'
  -- to limit additional reimbursement amount if more than 5 passengers
  IF (upper(p_exp_line_info.expense_type) = 'MILEAGE CLIENT EXTENSION') THEN
     IF (p_exp_line_info.numberPassengers > 5) THEN
           -- subtract the additional passenger rates from total amount
           p_exp_line_info.calculated_amount :=
                      round(p_exp_line_info.mileageRate *p_exp_line_info.tripDistance
                      - (p_exp_line_info.numberPassengers - 5)*
                              p_exp_line_info.passengerRateUsed *p_exp_line_info.tripDistance, 2) ;
           p_exp_line_info.copy_calc_amt_into_receipt_amt := 'Y';
     END IF;
  END IF;

  -- change the expense type as applicable
  IF (upper(p_exp_line_info.expense_type) = 'PERDIEM CLIENT EXTENSION') THEN
  i := p_end_date.count;
  -- if it is the employee hasn't traveled 3 hours within 16:00 and 07:00, reset the amount to zero.
  FOR j IN 1..i LOOP
     l_amount := p_amount(j);
     l_hours := (p_end_date(j) - p_start_date(j)) *24;
     IF ((l_hours > 6) AND (l_hours <= 8)) THEN
           l_date1 := to_date(to_char(trunc(p_start_date(j)), 'YY-MON-DD')||':16:00', 'YY-MON-DD:HH24:MI') ;
           l_date2 := to_date(to_char(trunc(p_start_date(j)+1), 'YY-MON-DD')||':07:00', 'YY-MON-DD:HH24:MI') ;
           IF (p_start_date(j) < to_date(to_char(trunc(p_start_date(j)), 'YY-MON-DD')||':07:00', 'YY-MON-DD:HH24:MI')) THEN
               l_date1 := to_date(to_char(trunc(p_start_date(j)-1), 'YY-MON-DD')||':16:00', 'YY-MON-DD:HH24:MI');
               l_date2 := to_date(to_char(trunc(p_start_date(j)), 'YY-MON-DD')||':07:00', 'YY-MON-DD:HH24:MI');
           END IF;
        -- if l_date1 >= l_start_date then l_end_date - l_date1 < 3 then set amount to zero
        -- else l_end_date - l_start_date < 3 then amount is set to zero
        IF (l_date1 >= p_start_date(j)) THEN
            IF (round(to_char(p_end_date(j) - l_date1)*24) < 3) THEN
               l_amount := 0;
               p_cust_pdm_rate(j) := 0;
               p_cust_meals_amount(j) := 0;
               p_cust_accommodation_amount(j) := 0;
            END IF;
        ELSIF (round(to_char(p_end_date(j) - p_start_date(j))*24) < 3) THEN
               l_amount := 0;
               p_cust_pdm_rate(j) := 0;
               p_cust_meals_amount(j) := 0;
               p_cust_accommodation_amount(j) := 0;
        END IF;
     END IF;
     l_tot_amount := l_tot_amount + l_amount;
  END LOOP;
  p_exp_line_info.calculated_amount := l_tot_amount ;
  p_exp_line_info.copy_calc_amt_into_receipt_amt := 'Y';
  END IF;
  */
  ------------------------------------------------------------------------
  l_debug_info := 'calculated_amount,copy_calc_amt_into_receipt_amt '|| p_exp_line_info.calculated_amount || ' ' || p_exp_line_info.copy_calc_amt_into_receipt_amt;
  AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_CUST_DFLEX_PKG', l_debug_info);
  ------------------------------------------------------------------------


EXCEPTION
  WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                    l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
        AP_WEB_UTILITIES_PKG.DisplayException(fnd_message.get);
END CustomCalculateAmount;

----------------------------------------------------------------------------
-- CUSTOMVALIDATECOSTCENTER:
--    Called by AP_WEB_VALIDATE_UTIL.ValidateCostCenter();
-- API provides a means of bypassing native cost center segment validation
-- and using custom code to validate cost center value.
--
--    Function returns TRUE if custom cost center segment validation is
-- enabled, or FALSE if native validation should be used.  By default,
-- we assume that native validation is used.
--
-- PARAMETERS:
--
--    p_cs_error        - Set this variable with your custom error message.
--                        If left blank, standard error message will be used.
--    p_CostCenterValue - The cost center entered by the user
--    p_CostCenterValid - TRUE if cost center is valid, otherwise FALSE;
--
----------------------------------------------------------------------------
----------------------------------------------------------------------------
FUNCTION CustomValidateCostCenter(
        p_cs_error              OUT NOCOPY VARCHAR2,
        p_CostCenterValue       IN  AP_EXPENSE_FEED_DISTS.cost_center%TYPE,
        p_CostCenterValid       IN OUT NOCOPY BOOLEAN,
        p_employee_id           IN NUMBER DEFAULT null) return BOOLEAN IS
----------------------------------------------------------------------------
BEGIN
  --
  -- Assume cost center is valid
  --
  p_CostCenterValid := TRUE;
 
  return(FALSE); -- return TRUE if using this extension to perform validation

  -- Note: If any error occurred and p_cs_error needs to be set by getting
  --       a FND message, make sure to use the following syntax:
  --
  -- p_CostCenterValid := FALSE;
  -- 
  -- FND_MESSAGE.SET_NAME('SQLAP', '<MESSAGE NAME>');
  -- p_cs_error :=  FND_MESSAGE.GET_ENCODED();
  --
  -- return(TRUE);

END CustomValidateCostCenter;
 
----------------------------------------------------------------------------
-- CUSTOMDEFAULTCOSTCENTER:
--    Called by AP_WEB_VALIDATE_UTIL.GetEmployeeInfo();
-- API provides a means of bypassing native cost center segment default
-- and using custom code to default cost center value.
--
--    Use employee_id to determing cost center within this custom
-- function and return the cost center segment value.
----------------------------------------------------------------------------
----------------------------------------------------------------------------
FUNCTION CustomDefaultCostCenter(
        p_employee_id           IN NUMBER) return VARCHAR2 IS
----------------------------------------------------------------------------
BEGIN
  --
  --
  --
 
  return(null); -- return Cost center value here
 
END CustomDefaultCostCenter;

----------------------------------------------------------------------------
-- CUSTOMVALIDATELINE:
--    Called by AP_WEB_VALIDATE_UTIL.ValidateExpLineCustomFields().
--    This API provides additional validation by adding errors to
--    the error stack.  
--    Use AP_WEB_UTILITIES_PKG.AddExpErrorNotEncoded to add error messages.
----------------------------------------------------------------------------
----------------------------------------------------------------------------
PROCEDURE CustomValidateLine(
  p_exp_header_info	IN AP_WEB_DFLEX_PKG.ExpReportHeaderRec,
  p_exp_line_info	IN AP_WEB_DFLEX_PKG.ExpReportLineRec,
  p_custom_fields_array	IN AP_WEB_DFLEX_PKG.CustomFields_A,
  p_message_array       IN OUT NOCOPY AP_WEB_UTILITIES_PKG.expError)
----------------------------------------------------------------------------
IS
  l_error_msg  		VARCHAR2(2000);
  l_start_date		Date;
  l_end_date		Date;
  l_dff_start_date	Date;
  l_dff_end_date	Date;
BEGIN
  ----------------------------------------------------------------------------
  -- Example code:  Custmize Validation and add to error stack
  --
  --IF (to_number(p_exp_line_info.receipt_amount) > 2000) THEN
  --    l_error_msg := 'Receipt Amount needs to be greater than 2000';
  --    AP_WEB_UTILITIES_PKG.AddExpErrorNotEncoded(p_message_array,
  --      				 l_error_msg,
  --      				 AP_WEB_UTILITIES_PKG.C_ErrorMessageType,
  --      				 'ReceiptAmount', -- Prompt
  --      				 p_exp_line_info.receipt_index);
  --ELSIF (...) THEN
  --END IF;

  -- Example code: To check if expense dates fall between start and end date
  -- you should know the attributes associated with start and end date segments
  -- defined in header DFF(Title : Expense Report)
  /*
  l_start_date := p_exp_line_info.start_date ;
  l_end_date := nvl(p_exp_line_info.end_date,p_exp_line_info.start_date);
  l_dff_start_date := fnd_date.canonical_to_date(p_exp_header_info.attribute2 );
  l_dff_end_date := fnd_date.canonical_to_date(p_exp_header_info.attribute3 );

  IF ((l_start_date is not null) AND (l_dff_start_date is not null) AND
      (l_dff_end_date is not null)) THEN
    IF (l_start_date < l_dff_start_date or l_start_date > l_dff_end_date or
        l_end_date < l_dff_start_date or l_end_date > l_dff_end_date) THEN

        l_error_msg := 'Date should be between ' || l_dff_start_date || ' - ' || l_dff_end_date;
        AP_WEB_UTILITIES_PKG.AddExpErrorNotEncoded(p_message_array,
        				 l_error_msg,
        				 AP_WEB_UTILITIES_PKG.C_ErrorMessageType,
        				 'Date', -- Prompt
        				 p_exp_line_info.receipt_index);
    --ELSIF (...) THEN
    END IF;
  END IF;
  */
--  NULL;

-------------------
-- start customization by SR:3-4686210481
-------------------
       IF (p_exp_line_info.taxId = 'null'  and
       nvl(p_exp_line_info.amount_includes_tax,'N') = 'Y') THEN
       l_error_msg := '税金を使用する設定の場合、VAT_CODE にNULLを設定することはできません。';
       AP_WEB_UTILITIES_PKG.AddExpErrorNotEncoded(p_message_array,
         l_error_msg,
         AP_WEB_UTILITIES_PKG.C_ErrorMessageType,
         'VatCode', -- Prompt
         p_exp_line_info.receipt_index);
       END IF;
-------------------
-- start customization by SR:3-4686210481
-------------------

END CustomValidateLine;

 -------------------------------------------------------------------------------
 -- Bug: 7422838 one-off for 7365109
 -- CustomGetCountyProvince:
 --    Called by AP_WEB_DB_EXPLINE_PKG.GetCountyProvince;
 -- API provides a means of bypassing native address style validation
 --
 -- Function returns TRUE if the validation for p_addressstyle passed in needs
 -- to be skipped.
 --
 -- PARAMETERS:
 --
 --    p_addressstyle    - The address style currently being used for validations
 --    p_region          - INOUT parameter, has a value when this funtion is called
 --                        can be overridden.
 -------------------------------------------------------------------------------
 -------------------------------------------------------------------------------
 FUNCTION CustomGetCountyProvince(
   p_addressstyle  IN             per_addresses.style%TYPE,
   p_region        IN OUT NOCOPY  per_addresses.region_1%TYPE) return BOOLEAN IS
 -------------------------------------------------------------------------------
 BEGIN
 
 ------------------------------------------------------------------------------
 -- Example
 -- IF p_addressstyle = 'CL_GLB' OR p_addressstyle = 'GT_GLB' THEN
 --    RETURN TRUE;
 -- ELSE
 --    RETURN FALSE;
 -- END IF;
 ------------------------------------------------------------------------------
 RETURN FALSE;
 END CustomGetCountyProvince;

END AP_WEB_CUST_DFLEX_PKG;

/

/*
l
/
SELECT LINE, SEQUENCE, NAME, TYPE, TEXT FROM user_errors
WHERE  name = 'AP_WEB_CUST_DFLEX_PKG'
AND    type = 'PACKAGE BODY'
/
*/

COMMIT;
EXIT;


