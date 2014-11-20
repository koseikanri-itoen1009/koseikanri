CREATE OR REPLACE PACKAGE xxinv520002c
AS
/*******************************************************************************
 *
 * Copyright(c) Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv520002c(spec)
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
    p1 IN VARCHAR2            -- 1.DammyParameter for Fine-Grain-Access-Control
   ,p2 IN VARCHAR2)           -- 2.DammyParameter for Fine-Grain-Access-Control
  RETURN VARCHAR2;
--
END xxinv520002c;
/
