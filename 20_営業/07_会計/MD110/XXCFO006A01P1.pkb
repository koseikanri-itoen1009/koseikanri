CREATE OR REPLACE PACKAGE BODY XXCFO006A01P1
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name    : XXCFO006A01P1(body)
 * Description     : APWI�Z�L�����e�B
 * MD.050          : MD050_CFO_006_A01_APWI�Z�L�����e�B
 * MD.070          : MD050_CFO_006_A01_APWI�Z�L�����e�B
 * Version         : 1.1
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  get_policy_condition      F    VAR    WHERE��i�������匠������ɂ��Z�L�����e�B�ݒ�j
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05   1.0    SCS ���c �E�l    ����쐬
 *  2015-12-02   1.1    SCSK���H ���O    E_�{�ғ�_13393�Ή�
 *  2016-01-26   1.2    SCSK���H ���O    E_�{�ғ�_13393�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
--
--
--################################  �Œ蕔 END   ##################################
--
  /**********************************************************************************
   * Function Name    : get_policy_condition
   * Description      : ���O�C�����[�U��������擾�֐�
   ***********************************************************************************/
  FUNCTION get_policy_condition(
    p1 IN VARCHAR2
   ,p2 IN VARCHAR2)
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'XXCFO006A01P1.get_policy_condition';     -- �v���O������
    cv_profile_user_id  CONSTANT VARCHAR2(7) := 'USER_ID' ;                                 -- ���[�U�[ID
    cn_security_0       CONSTANT NUMBER(2) := 0 ;                                           -- ���_�E����
    cn_security_1       CONSTANT NUMBER(2) := 1 ;                                           -- ����
    cn_security_2       CONSTANT NUMBER(2) := 2 ;                                           -- �w��
    cn_security_99      CONSTANT NUMBER(2) := 99 ;                                          -- ���O�C�����[�U�[�ΏۂȂ�
-- 2015.12.02 Ver1.1 Add Start
    cn_security_3       CONSTANT NUMBER(2) := 3 ;                                           -- ���v�Ɖ�/�o��Z�������R�f�[�^�o��
    cn_appli_id_101     CONSTANT NUMBER(3) := 101 ;                                         -- �A�v���P�[�V����ID:101
-- 2016.01.26 Ver1.2 Add Start
    cn_program_id       CONSTANT NUMBER    := fnd_global.conc_program_id;                   -- �R���J�����g�v���O����ID
    cn_prog_appl_id     CONSTANT NUMBER    := fnd_global.prog_appl_id;                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    cv_conc_name        CONSTANT VARCHAR2(12) := 'XXCCP007A08C';                            -- �o��Z�������R�f�[�^�o��
-- 2016.01.26 Ver1.2 Add End
    cv_dept_user        CONSTANT VARCHAR2(13) := 'XXCFO%DPT_USR';                           -- �E�ӁF���v�Ɖ�
    cv_profile_resp_id  CONSTANT VARCHAR2(7)  := 'RESP_ID';                                 -- �E��ID
    cv_xx03_department  CONSTANT VARCHAR2(15) := 'XX03_DEPARTMENT';                         -- ����
-- 2015.12.02 Ver1.1 Add End
    cv_yes_no_y         CONSTANT VARCHAR2(1) := 'Y' ;                                       -- Y
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_where            VARCHAR2(4000) ;                        -- �߂�l�pWHERE��
    ln_security         NUMBER(2) ;                             -- 0:���_�E����/1:����/2:�w��/99:���O�C�����[�U�[�ΏۂȂ�
    lv_papf_dff28       PER_ALL_PEOPLE_F.ATTRIBUTE28%TYPE ;     -- ���O�C�����[�U�[�ɕR�t����������
    ln_set_of_books_id  AP_INVOICES_ALL.SET_OF_BOOKS_ID%TYPE ;  -- ��v����ID
    ln_org_id           AP_INVOICES_ALL.ORG_ID%TYPE ;           -- �g�DID
-- 2015.12.02 Ver1.1 Add Start
    lt_resp_id          fnd_responsibility.responsibility_key%TYPE ; -- �E��ID
-- 2015.12.02 Ver1.1 Add End
-- 2016.01.26 Ver1.2 Add Start
    lt_program_id       fnd_concurrent_programs.concurrent_program_id%TYPE ; -- �R���J�����g�v���O����ID
-- 2016.01.26 Ver1.2 Add End
--
  BEGIN
--
    -- ====================================================
    -- ���O�C�����[�U�[����ݒ蔻��
    -- ===================================================
--
    -- ����������擾
    BEGIN
      SELECT cn_security_0                              cn_security_0,          -- ���_�E����
             ppf.attribute28                            attribute28,            -- ��������
             fnd_profile.value( 'GL_SET_OF_BKS_ID' )    gl_set_of_bks_id,       -- ��v����ID
             fnd_profile.value( 'ORG_ID' )              org_id                 -- �g�DID
      INTO   ln_security,
             lv_papf_dff28,
             ln_set_of_books_id,
             ln_org_id
      FROM   per_all_people_f ppf,
             fnd_user fu
      WHERE  fu.employee_id = ppf.person_id
      AND    ppf.current_employee_flag = cv_yes_no_y
      AND    TRUNC( SYSDATE ) BETWEEN ppf.effective_start_date
                              AND     ppf.effective_end_date
      AND    fu.user_id = fnd_profile.value( cv_profile_user_id )
      AND    ppf.attribute28 IS NOT NULL ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_security := cn_security_99 ;
--
    END ;
--
    -- ���O�C�����[�U�[�ɕR�t���������傪���݂����ꍇ
    IF (ln_security = cn_security_0) THEN
      BEGIN
        -- ====================================================
        -- �����o������
        -- ===================================================
        SELECT cn_security_1    cn_security_1         -- ����
        INTO   ln_security
        FROM   xxcfo_security_zaimu_v xszv
        WHERE  xszv.lookup_code = lv_papf_dff28 ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL ;
--
      END ;
    END IF ;
--
-- 2016.01.26 Ver1.2 Add Start
    IF (ln_security = cn_security_0) THEN
      BEGIN
        -- ====================================================
        -- �E�ӁFSALES_XXXX_���v�Ɖ�_��v�̔���
        -- ===================================================
        SELECT fnd_profile.value(cv_profile_resp_id)  resp_id        -- �E��ID
        INTO   lt_resp_id
        FROM   fnd_responsibility fr   -- �E��
        WHERE  fr.application_id     = cn_appli_id_101
        AND    fr.responsibility_key LIKE cv_dept_user
        AND    fr.responsibility_id  = fnd_profile.value(cv_profile_resp_id) ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
      -- �E�ӁFSALES_XXXX_���v�Ɖ�_��v�̏ꍇ
      IF ( lt_resp_id IS NOT NULL ) THEN
        BEGIN
          -- ====================================================
          -- �o��Z�������R�f�[�^�o�͂̔���
          -- ===================================================
          SELECT fcp.concurrent_program_id  program_id
          INTO   lt_program_id
          FROM   fnd_concurrent_programs fcp
          WHERE  fcp.application_id          = cn_prog_appl_id
          AND    fcp.concurrent_program_name = cv_conc_name
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- �o��Z�������R�f�[�^�o�͂̏ꍇ
        IF ( lt_program_id = cn_program_id ) THEN
          ln_security := cn_security_3;  -- ���v�Ɖ�/�o��Z�������R�f�[�^�o��
        END IF;
      END IF;
    END IF;
--
-- 2016.01.26 Ver1.2 Add End
    -- ���_�̏ꍇ
    IF (ln_security = cn_security_0) THEN
      BEGIN
        -- ====================================================
        -- �w���֘A����
        -- ===================================================
        SELECT cn_security_2    cn_security_2         -- �w��
        INTO   ln_security
        FROM   xxcfo_security_koubai_v xskv
        WHERE  xskv.lookup_code = lv_papf_dff28 ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL ;
      END ;
-- 2016.01.26 Ver1.2 Del Start
-- 2015.12.02 Ver1.1 Add Start
--      BEGIN
--        -- ====================================================
--        -- �E�ӁFSALES_XXXX_���v�Ɖ�_��v�̔���
--        -- ===================================================
--        SELECT cn_security_3    cn_security_3                  -- ���v�Ɖ�
--              ,fnd_profile.value(cv_profile_resp_id)  resp_id  -- �E��ID
--        INTO   ln_security
--              ,lt_resp_id
--        FROM   fnd_responsibility fr   -- �E��
--        WHERE  fr.application_id     = cn_appli_id_101
--        AND    fr.responsibility_key LIKE cv_dept_user
--        AND    fr.responsibility_id  = fnd_profile.value(cv_profile_resp_id) ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          NULL;
--      END;
-- 2015.12.02 Ver1.1 Add End
-- 2016.01.26 Ver1.2 Del End
    END IF ;
--
    -- WHERE��ǉ�����i����,��������Ȃ��j
    IF (ln_security IN ( cn_security_1 ,cn_security_99 )) THEN
      NULL ;
-- 2015.12.02 Ver1.1 Add Start
    -- ���v�Ɖ�/�o��Z�������R�f�[�^�o�͂̏ꍇ
    ELSIF (ln_security = cn_security_3) THEN
      -- ====================================================
      -- �K�w����N�[��
      -- ===================================================
      lv_where := ' ( EXISTS (  SELECT 1 ' ;
      lv_where := lv_where || ' FROM   apps.fnd_flex_value_rule_usages   ffvru';  -- �Z�L�����e�B���[������
      lv_where := lv_where || '       ,apps.fnd_flex_value_rules         ffvr';   -- �Z�L�����e�B���[��
      lv_where := lv_where || '       ,apps.fnd_flex_value_sets          ffvs';   -- �Z�L�����e�B���[���Z�b�g
      lv_where := lv_where || '       ,apps.fnd_flex_value_rule_lines    ffvrl';  -- �Z�L�����e�B���[���v�f
      lv_where := lv_where || ' WHERE  ffvru.application_id              = ' || cn_appli_id_101 || ' ' ;
      lv_where := lv_where || ' AND    ffvs.flex_value_set_name          = ' || '''' || cv_xx03_department || '''' || ' ' ;
      lv_where := lv_where || ' AND    ffvr.flex_value_set_id            = ffvs.flex_value_set_id ' ;
      lv_where := lv_where || ' AND    ffvru.flex_value_rule_id          = ffvr.flex_value_rule_id ' ;
      lv_where := lv_where || ' AND    ffvru.flex_value_set_id           = ffvr.flex_value_set_id ' ;
      lv_where := lv_where || ' AND    ffvrl.flex_value_rule_id          = ffvr.flex_value_rule_id ' ;
      lv_where := lv_where || ' AND    ffvrl.flex_value_set_id           = ffvr.flex_value_set_id ' ;
      lv_where := lv_where || ' AND    ffvrl.flex_value_low              = ap_invoices_all.attribute3 ' ;
      lv_where := lv_where || ' AND    ap_invoices_all.set_of_books_id   = ' || ln_set_of_books_id || ' ' ;
      lv_where := lv_where || ' AND    ap_invoices_all.org_id            = ' || ln_org_id || ' ' ;
      lv_where := lv_where || ' AND    ffvru.responsibility_id           = ' || lt_resp_id || ' ) ) ' ;
-- 2015.12.02 Ver1.1 Add End
    ELSE
      -- ====================================================
      -- �e���_�E����/�w���֘A���ʐݒ�
      -- ===================================================
      -- ====================================================
      -- �����_�E����N�[��
      -- ===================================================
      lv_where := '(( EXISTS ( SELECT 1 ' ;
      lv_where := lv_where || 'FROM dual ' ;
      lv_where := lv_where || 'WHERE ap_invoices_all.attribute3 = ' || '''' || lv_papf_dff28 || '''' || ' ' ;
      lv_where := lv_where || 'AND ap_invoices_all.set_of_books_id = ' || ln_set_of_books_id || ' ' ;
      lv_where := lv_where || 'AND ap_invoices_all.org_id = ' || ln_org_id || ' ) ' ;
--
      -- ====================================================
      -- �����_�E����x����
      -- ===================================================
      lv_where := lv_where || 'OR EXISTS ( SELECT 1 ' ;
      lv_where := lv_where || 'FROM xxcfo_pay_group_v xpgv ' ;
      lv_where := lv_where || 'WHERE xpgv.attribute2 = ' || '''' || lv_papf_dff28 || '''' || ' '  ;
      lv_where := lv_where || 'AND ap_invoices_all.pay_group_lookup_code = xpgv.lookup_code ' ;
      lv_where := lv_where || 'AND ap_invoices_all.set_of_books_id = ' || ln_set_of_books_id || ' ' ;
      lv_where := lv_where || 'AND ap_invoices_all.org_id = ' || ln_org_id || ' )) ' ;
--
      -- ====================================================
      -- �w���֘A
      -- ===================================================
      IF (ln_security = cn_security_2) THEN
        lv_where := lv_where || 'OR EXISTS ( SELECT 1 ' ;
        lv_where := lv_where || 'FROM po_vendor_sites_all pvsa ' ;
        lv_where := lv_where || 'WHERE pvsa.org_id = ' || ln_org_id || ' ' ;
        lv_where := lv_where || 'AND pvsa.purchasing_site_flag = '|| '''' || cv_yes_no_y || '''' || ' ' ;
        lv_where := lv_where || 'AND pvsa.vendor_site_id = ap_invoices_all.vendor_site_id ' ;
        lv_where := lv_where || 'AND ap_invoices_all.set_of_books_id = ' || ln_set_of_books_id || ' ' ;
        lv_where := lv_where || 'AND pvsa.org_id = ap_invoices_all.org_id ' ;
        lv_where := lv_where || ')) ' ;
--
      ELSE
      -- ====================================================
      -- �w���֘A�ȊO
      -- ===================================================
        lv_where := lv_where || ') ' ;
      END IF ;
    END IF ;
--
    RETURN lv_where ;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_policy_condition;
--
--
END XXCFO006A01P1;
/
