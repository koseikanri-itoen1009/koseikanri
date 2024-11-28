CREATE OR REPLACE PACKAGE APPS.xxcso_route_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_ROUTE_COMMON_PKG(spec)
 * Description      : ROUTE�֘A���ʊ֐��i�c�Ɓj
 * MD.050           : XXCSO_View�E���ʊ֐��ꗗ
 * Version          : 1.2
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  validate_route_no      F     B     ���[�g�m���Ó����`�F�b�N
 *  distribute_sales_plan  P     -     ����v����ʔz������
 *  calc_visit_times       F     N     ���[�g�m���K��񐔎Z�o����
 *  validate_route_no_p    P     -     ���[�g�m���Ó����`�F�b�N(�v���V�[�W��)
 *  isCustomerVendor       F     B     �u�c�ƑԔ���֐�
 *  calc_visit_times_f     F     N     ���[�g�m���K��񐔎Z�o����
 *  get_visit_rank_f       F     V     �K�⃉���N�擾
 *  get_number_of_visits_f F     N     �v��K��񐔎擾�擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/16    1.0   Kenji.Sai       �V�K�쐬
 *  2008/12/12          Kazuo.Satomura  ���[�g�m���K��񐔎Z�o�����ǉ�
 *  2008/12/17          Noriyuki.Yabuki ���[�g�m���Ó����`�F�b�N�̏o�͍���(�G���[���R)�ǉ�
 *  2009/01/09          Kazumoto.Tomio  ���[�g�m���Ó����`�F�b�N(�v���V�[�W��)�ǉ�
 *  2009/01/20          T.Maruyama      �u�c�ƑԔ���֐��ǉ�
 *  2009/02/19    1.0   Mio.Maruyama    ���[�g�m���K��񐔎Z�o�����ǉ�
 *  2009-05-01    1.1   Tomoko.Mori     T1_0897�Ή�
 *  2024-10-23    1.2   Toru.Okuyama    E_�{�ғ�_20170�Ή��F�K�⃉���N�擾�A�v��K��񐔎擾�擾�̒ǉ�
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �j�����i�[����z��
  TYPE g_day_of_week_ttype IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Function Name    : validate_route_no
   * Description      : ���[�g�m���Ó����`�F�b�N
   ***********************************************************************************/
  FUNCTION validate_route_no(
    iv_route_number  IN  VARCHAR2,    -- ���[�g�m��
    ov_error_reason  OUT VARCHAR2     -- �G���[���R
  ) RETURN BOOLEAN;
--   
-- 
  /**********************************************************************************
   * Procedure Name   : distribute_sales_plan
   * Description      : ����v����ʔz������
   ***********************************************************************************/
  PROCEDURE distribute_sales_plan(
    iv_year_month                  IN VARCHAR2,                                            -- �N���i�����FYYYYMM�j
    it_sales_plan_amt              IN xxcso_in_sales_plan_month.sales_plan_amt%TYPE,       -- ���Ԕ���v����z
    it_route_number                IN xxcso_in_route_no.route_no%TYPE,                     -- ���[�g�m�� 
    on_day_on_month                OUT NUMBER,                                             -- �Y�����̓���
    on_visit_daytimes              OUT NUMBER,                                             -- ���Y���̖K�����
    ot_sales_plan_day_amt_1        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 1���ړ��ʔ���v����z
    ot_sales_plan_day_amt_2        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 2���ړ��ʔ���v����z
    ot_sales_plan_day_amt_3        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 3���ړ��ʔ���v����z
    ot_sales_plan_day_amt_4        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 4���ړ��ʔ���v����z
    ot_sales_plan_day_amt_5        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 5���ړ��ʔ���v����z
    ot_sales_plan_day_amt_6        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 6���ړ��ʔ���v����z
    ot_sales_plan_day_amt_7        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 7���ړ��ʔ���v����z
    ot_sales_plan_day_amt_8        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 8���ړ��ʔ���v����z
    ot_sales_plan_day_amt_9        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 9���ړ��ʔ���v����z
    ot_sales_plan_day_amt_10       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 10���ړ��ʔ���v����z
    ot_sales_plan_day_amt_11       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 11���ړ��ʔ���v����z
    ot_sales_plan_day_amt_12       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 12���ړ��ʔ���v����z
    ot_sales_plan_day_amt_13       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 13���ړ��ʔ���v����z
    ot_sales_plan_day_amt_14       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 14���ړ��ʔ���v����z
    ot_sales_plan_day_amt_15       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 15���ړ��ʔ���v����z
    ot_sales_plan_day_amt_16       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 16���ړ��ʔ���v����z
    ot_sales_plan_day_amt_17       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 17���ړ��ʔ���v����z
    ot_sales_plan_day_amt_18       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 18���ړ��ʔ���v����z
    ot_sales_plan_day_amt_19       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 19���ړ��ʔ���v����z
    ot_sales_plan_day_amt_20       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 20���ړ��ʔ���v����z
    ot_sales_plan_day_amt_21       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 21���ړ��ʔ���v����z
    ot_sales_plan_day_amt_22       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 22���ړ��ʔ���v����z
    ot_sales_plan_day_amt_23       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 23���ړ��ʔ���v����z
    ot_sales_plan_day_amt_24       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 24���ړ��ʔ���v����z
    ot_sales_plan_day_amt_25       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 25���ړ��ʔ���v����z
    ot_sales_plan_day_amt_26       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 26���ړ��ʔ���v����z
    ot_sales_plan_day_amt_27       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 27���ړ��ʔ���v����z
    ot_sales_plan_day_amt_28       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 28���ړ��ʔ���v����z
    ot_sales_plan_day_amt_29       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 29���ړ��ʔ���v����z
    ot_sales_plan_day_amt_30       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 30���ړ��ʔ���v����z
    ot_sales_plan_day_amt_31       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 31���ړ��ʔ���v����z
    ov_errbuf                      OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode                     OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg                      OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  );
--
-- 
  /**********************************************************************************
   * Function Name    : calc_visit_times
   * Description      : ���[�g�m���K��񐔎Z�o����
   ***********************************************************************************/
  PROCEDURE calc_visit_times(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ���[�g�m��
    ,on_times        OUT NOCOPY NUMBER                          -- �K���
    ,ov_errbuf       OUT NOCOPY VARCHAR2                        -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode      OUT NOCOPY VARCHAR2                        -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg       OUT NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  );
-- 
--
  /**********************************************************************************
   * Function Name    : validate_route_no_p
   * Description      : ���[�g�m���Ó����`�F�b�N(�v���V�[�W��)
   ***********************************************************************************/
  PROCEDURE validate_route_no_p(
     iv_route_number  IN  VARCHAR2            -- ���[�g�m��
    ,ov_retcode       OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h  --# �Œ� #
    ,ov_error_reason  OUT VARCHAR2            -- �G���[���R
  );
--
--
  /**********************************************************************************
   * Function Name    : isCustomerVendor
   * Description      : �u�c�ƑԔ���֐�
   ***********************************************************************************/
  FUNCTION isCustomerVendor(
     iv_cust_gyoutai  IN  VARCHAR2            -- �Ƒԁi�����ށj
  ) RETURN VARCHAR2;
--
--
  /**********************************************************************************
   * Function Name    : calc_visit_times_f
   * Description      : �K��񐔎Z�o����
   ***********************************************************************************/
  FUNCTION calc_visit_times_f(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ���[�g�m��
  ) RETURN NUMBER;
--
-- Ver 1.2 Add Start
  /**********************************************************************************
   * Function Name    : get_visit_rank_f
   * Description      : �K�⃉���N�擾
   ***********************************************************************************/
  FUNCTION get_visit_rank_f(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ���[�g�m��
  ) RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_number_of_visits_f
   * Description      : �v��K��񐔎擾�擾
   ***********************************************************************************/
  FUNCTION get_number_of_visits_f(
     iv_route_number     IN  xxcso_in_route_no.route_no%TYPE, -- ���[�g�m��
     id_year_month       IN  DATE,                            -- �������
     in_day_offset       IN  NUMBER                           -- ��������̃I�t�Z�b�g����
  ) RETURN NUMBER;
-- Ver 1.2 Add End
--
END xxcso_route_common_pkg;
/
