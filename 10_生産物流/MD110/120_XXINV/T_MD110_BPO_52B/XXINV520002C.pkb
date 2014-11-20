CREATE OR REPLACE PACKAGE BODY xxinv520002c
AS
/*******************************************************************************
 *
 * Copyright(c) Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv520002c(body)
 * Description            : Package of Fine-Grain-Access-Control for GMD_RECIPES_B
 * Version                : 1.0
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------
 *   gmd_recipes_b_sel    F    VAR   Function for GMD_RECIPES_B
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------
 *  2008/06/04   1.0   Oracle—é–Ø—Y‘å   Create
 *
 *******************************************************************************/
--
  --Function for GMD_RECIPES_B
  FUNCTION gmd_recipes_b_sel(
    p1 IN VARCHAR2
   ,p2 IN VARCHAR2)
  RETURN VARCHAR2
  IS
--
    --Static
    cv_prg_name CONSTANT VARCHAR2(100) := 'XXINV520002C.GMD_RECIPES_B_SEL';     -- ProgramName
    cv_profname CONSTANT VARCHAR2(100) := 'XXCMN_RECIPES_FGAC_PROF';            -- ProfileName
    cv_profvaly CONSTANT VARCHAR2(100) := 'Y';                                  -- ProfileValue(Y)
--
    --Variable
    lv_where     VARCHAR2(4000);
    lv_flag      VARCHAR2(100);
    lv_profvalue VARCHAR2(100);
--
  BEGIN
--
    --Initialize
    lv_where := '';
    lv_flag  := '';
--
    --Get Profile
    lv_profvalue := FND_PROFILE.VALUE(cv_profname);
--
    --PROFILE VALUE : 'Y'
    IF (lv_profvalue = cv_profvaly) THEN
      lv_where := 'EXISTS ('||
                  'SELECT 1 '||
                  'FROM gmd_routings_b gb '||
                  'WHERE gb.routing_id = gmd_recipes_b.routing_id '||
                  'AND gb.routing_class IN (''61'',''62''))';
    END IF;
--
    RETURN lv_where;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||' : '||SQLERRM,1,5000),TRUE);
--
  END gmd_recipes_b_sel;
--
END xxinv520002c;
/
