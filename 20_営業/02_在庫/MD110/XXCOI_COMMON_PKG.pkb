CREATE OR REPLACE PACKAGE BODY XXCOI_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI_COMMON_PKG(body)
 * Description      : ���ʊ֐��p�b�P�[�W(�݌�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COI
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  ORG_ACCT_PERIOD_CHK        �݌ɉ�v���ԃ`�F�b�N
 *  GET_ORGANIZATION_ID        �݌ɑg�DID�擾
 *  GET_BELONGING_BASE         �������_�R�[�h�擾1
 *  GET_BASE_CODE              �������_�R�[�h�擾2
 *  GET_MEANING                LOOKUP���擾
 *  GET_CMPNT_COST             �W�������擾
 *  GET_DISCRETE_COST          �c�ƌ����擾
 *  GET_TRANSACTION_TYPE_ID    ����^�C�vID�擾
 *  GET_ITEM_INFO              �i�ڏ��擾1
 *  GET_ITEM_CODE              �i�ڏ��擾2
 *  GET_UOM_DISABLE_INFO       �P�ʖ��������擾
 *  GET_SUBINVENTORY_INFO1     �ۊǏꏊ���擾1
 *  GET_SUBINVENTORY_INFO2     �ۊǏꏊ���擾2
 *  GET_MANAGE_DEPT_F          �Ǘ��۔��ʃt���O�擾
 *  GET_LOOKUP_VALUES          �N�C�b�N�R�[�h�}�X�^���擾
 *  CONVERT_WHOUSE_SUBINV_CODE HHT�ۊǏꏊ�R�[�h�ϊ� �q�ɕۊǏꏊ�R�[�h�ϊ�
 *  CONVERT_EMP_SUBINV_CODE    HHT�ۊǏꏊ�R�[�h�ϊ� �c�ƎԕۊǏꏊ�R�[�h�ϊ�
 *  CONVERT_CUST_SUBINV_CODE   HHT�ۊǏꏊ�R�[�h�ϊ� �a����ۊǏꏊ�R�[�h�ϊ�
 *  CONVERT_BASE_SUBINV_CODE   HHT�ۊǏꏊ�R�[�h�ϊ� ���C���q�ɕۊǏꏊ�R�[�h�ϊ�
 *  CHECK_CUST_STATUS          HHT�ۊǏꏊ�R�[�h�ϊ� �ڋq�X�e�[�^�X�`�F�b�N
 *  CONVERT_SUBINV_CODE        HHT�ۊǏꏊ�R�[�h�ϊ�
 *  GET_DISPOSITION_ID         ����Ȗڕʖ�ID�擾
 *  ADD_HHT_ERR_LIST_DATA      HHT���捞�G���[�o��
 *  GET_DISPOSITION_ID_2       ����Ȗڕʖ�ID�擾2
 *  GET_ITEM_INFO2             �i�ڏ��擾(�i��ID�A�P�ʃR�[�h)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/23    1.0   T.Nishikawa      �V�K�쐬
 *  2009/03/13    1.1   H.Wada           get_subinventory_info1 �擾�����C��(��Q�ԍ�T1_0040)
 *  2009/03/24    1.2   S.Kayahara       �ŏI�s��/�ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;   -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;     -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;    -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATIO
--N_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DAT
--BUSINESS
  cd_business_date          CONSTANT DATE        := xxccp_common_pkg2.get_process_date;   -- �Ɩ����t
  cn_business_group_id      CONSTANT NUMBER      := fnd_global.per_business_group_id;     -- BUSINESS_GROUP_ID
--E
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI_COMMON_PKG';       -- �p�b�P�[�W��
--
--################################  �Œ蕔 END   ##################################
--
--
/************************************************************************
 * Function Name   : ORG_ACCT_PERIOD_CHK
 * Description     : �Ώۓ��ɑΉ�����݌ɉ�v���Ԃ��I�[�v�����Ă��邩��
 *                   �`�F�b�N����B
 ************************************************************************/
  PROCEDURE org_acct_period_chk(
    in_organization_id IN  NUMBER       -- �݌ɑg�DID
   ,id_target_date     IN  DATE         -- �Ώۓ�
   ,ob_chk_result      OUT BOOLEAN      -- �X�e�[�^�X
   ,ov_errbuf          OUT VARCHAR2     -- �G���[���b�Z�[�W
   ,ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    cv_prg_name        CONSTANT VARCHAR2(30) := 'org_acct_period_chk';
    lv_open_flg        VARCHAR2(10);
  BEGIN
    ob_chk_result := FALSE;
    IF (in_organization_id IS NULL OR id_target_date IS NULL) THEN
      ov_retcode := cv_status_error;    -- �ُ�:2
    ELSE
      ov_retcode := cv_status_normal;   -- ����:0
      SELECT oap.open_flag AS open_flag
      INTO   lv_open_flg
      FROM   org_acct_periods oap
      WHERE  oap.organization_id = in_organization_id
      AND    id_target_date BETWEEN oap.period_start_date AND oap.schedule_close_date;
      --
      IF (lv_open_flg = 'Y') THEN
        ob_chk_result := TRUE;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END org_acct_period_chk;
/************************************************************************
 * Function Name   : GET_ORGANIZATION_ID
 * Description     : �̔������̈�̍݌ɑg�DID���擾����B
 ************************************************************************/
  FUNCTION get_organization_id(
    iv_organization_code IN VARCHAR2    -- �݌ɑg�D�R�[�h
  ) RETURN NUMBER
  IS
    ln_organization_id NUMBER;
  BEGIN
    BEGIN
      SELECT mp.organization_id AS organization_id -- �g�DID
      INTO   ln_organization_id
      FROM   mtl_parameters mp                     -- �g�D�p�����[�^
      WHERE  mp.organization_code = iv_organization_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_organization_id;
  END get_organization_id;
/************************************************************************
 * Procedure Name  : GET_BELONGING_BASE
 * Description     : ���O�C�����[�U�[�ɕR�t���������_�R�[�h���擾����B
 ************************************************************************/
  PROCEDURE get_belonging_base(
    in_user_id      IN  NUMBER          -- ���[�U�[ID
   ,id_target_date  IN  DATE            -- �Ώۓ�
   ,ov_base_code    OUT VARCHAR2        -- ���_�R�[�h
   ,ov_errbuf       OUT VARCHAR2        -- �G���[���b�Z�[�W
   ,ov_retcode      OUT VARCHAR2        -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg       OUT VARCHAR2        -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    cv_prg_name CONSTANT VARCHAR2(99) := 'get_belonging_base';
  BEGIN
    IF (in_user_id IS NULL OR id_target_date IS NULL) THEN
      ov_retcode := cv_status_error;    -- �ُ�:2
    ELSE
      ov_retcode := cv_status_normal;   -- ����:0
      SELECT CASE
             WHEN aaf.ass_attribute2 IS NULL                -- ���ߓ�
             THEN aaf.ass_attribute5
             WHEN TO_DATE(aaf.ass_attribute2,'YYYYMMDD') > id_target_date
             THEN aaf.ass_attribute6                        -- ���_�R�[�h�i���j
             ELSE aaf.ass_attribute5                        -- ���_�R�[�h�i�V�j
             END  AS base_code
      INTO   ov_base_code                                   -- �����_�R�[�h
      FROM   fnd_user                 fnu                   -- ���[�U�[�}�X�^
            ,per_all_people_f         apf                   -- �]�ƈ��}�X�^
            ,per_all_assignments_f    aaf                   -- �]�ƈ������}�X�^(�A�T�C�����g)
            ,per_person_types         ppt                   -- �]�ƈ��敪�}�X�^
      WHERE  fnu.user_id            = in_user_id            -- FND_GLOBAL.USER_ID
      AND    apf.person_id          = fnu.employee_id
      AND    TRUNC(id_target_date) BETWEEN TRUNC(apf.effective_start_date)
      AND    TRUNC(NVL(apf.effective_end_date,id_target_date))
      AND    ppt.business_group_id  = cn_business_group_id
      AND    ppt.system_person_type = 'EMP'
      AND    ppt.active_flag        = 'Y'
      AND    apf.person_type_id     = ppt.person_type_id
      AND    aaf.person_id          = apf.person_id;
      --
      IF (ov_base_code IS NULL) THEN
        ov_retcode := cv_status_error;    -- �ُ�:2
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_belonging_base;
/************************************************************************
 * Function Name   : GET_BASE_CODE
 * Description     : �������_�R�[�h�擾�̃t�@���N�V�����@�\�B
 ************************************************************************/
  FUNCTION get_base_code(
    in_user_id      IN NUMBER             -- ���[�U�[ID
   ,id_target_date  IN DATE               -- �Ώۓ�
  ) RETURN VARCHAR2
  IS
    lv_base_code    VARCHAR2(4) := NULL;  -- ���_�R�[�h
    ln_user_id      NUMBER;
    ld_target_date  DATE;
  BEGIN
    IF (in_user_id IS NULL) THEN
      ln_user_id := fnd_global.user_id;
    ELSE
      ln_user_id := in_user_id;
    END IF;
    IF (id_target_date IS NULL) THEN
      ld_target_date := SYSDATE;
    ELSE
      ld_target_date := id_target_date;
    END IF;
    BEGIN
      SELECT CASE
             WHEN aaf.ass_attribute2 IS NULL                -- ���ߓ�
             THEN aaf.ass_attribute5
             WHEN TO_DATE(aaf.ass_attribute2,'YYYYMMDD') > ld_target_date
             THEN aaf.ass_attribute6                        -- ���_�R�[�h�i���j
             ELSE aaf.ass_attribute5                        -- ���_�R�[�h�i�V�j
             END  AS base_code
      INTO   lv_base_code                                   -- �����_�R�[�h
      FROM   fnd_user                 fnu                   -- ���[�U�[�}�X�^
            ,per_all_people_f         apf                   -- �]�ƈ��}�X�^
            ,per_all_assignments_f    aaf                   -- �]�ƈ������}�X�^(�A�T�C�����g)
            ,per_person_types         ppt                   -- �]�ƈ��敪�}�X�^
      WHERE  fnu.user_id            = ln_user_id            -- FND_GLOBAL.USER_ID
      AND    apf.person_id          = fnu.employee_id
      AND    TRUNC(ld_target_date) BETWEEN TRUNC(apf.effective_start_date)
      AND    TRUNC(NVL(apf.effective_end_date,ld_target_date))
      AND    ppt.business_group_id  = cn_business_group_id
      AND    ppt.system_person_type = 'EMP'
      AND    ppt.active_flag        = 'Y'
      AND    apf.person_type_id     = ppt.person_type_id
      AND    aaf.person_id          = apf.person_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN lv_base_code;
  END get_base_code;
/************************************************************************
 * Function Name   : GET_MEANING
 * Description     : �N�C�b�N�R�[�h�̎Q�ƃ^�C�v�E�Q�ƃR�[�h�̓��e���擾����B
 ************************************************************************/
  FUNCTION get_meaning(
    iv_lookup_type IN VARCHAR2          -- �Q�ƃ^�C�v
   ,iv_lookup_code IN VARCHAR2          -- �Q�ƃR�[�h
  ) RETURN VARCHAR2
  IS
    lv_translated_string VARCHAR2(500) := NULL;
  BEGIN
    BEGIN
      SELECT flv.meaning AS meaning
      INTO   lv_translated_string
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_code   = iv_lookup_code
      AND    flv.lookup_type   = iv_lookup_type
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = 'Y'
      AND    SYSDATE BETWEEN NVL(flv.start_date_active,SYSDATE)
                     AND     NVL(flv.end_date_active,  SYSDATE);
      --
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN lv_translated_string;
  END get_meaning;
/************************************************************************
 * Procedure Name  : GET_CMPNT_COST
 * Description     : �i��ID�����ɕW���������擾���܂��B
 ************************************************************************/
  PROCEDURE get_cmpnt_cost(
    in_item_id      IN  NUMBER          -- �i��ID
   ,in_org_id       IN  NUMBER          -- �g�DID
   ,id_period_date  IN  DATE            -- �Ώۓ�
   ,ov_cmpnt_cost   OUT VARCHAR2        -- �W������
   ,ov_errbuf       OUT VARCHAR2        -- �G���[���b�Z�[�W
   ,ov_retcode      OUT VARCHAR2        -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg       OUT VARCHAR2        -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    cv_prg_name     CONSTANT VARCHAR2(99) := 'get_cmpnt_cost';
    lv_calendar_code         VARCHAR2(4);       -- ����
  BEGIN
    IF (in_item_id      IS NULL
      OR in_org_id      IS NULL
      OR id_period_date IS NULL) THEN
      ov_retcode := cv_status_error;    -- �ُ�:2
    ELSE
      ov_retcode := cv_status_normal;   -- ����:0
      --
      -- ===================================
      --  �N�x�ݒ�
      -- ===================================
      lv_calendar_code := TO_CHAR(id_period_date,'YYYY');
      IF (id_period_date < TO_DATE(lv_calendar_code||'0501','YYYYMMDD')) THEN
        -- �Ώۓ���5/1�ȑO�̏ꍇ�A�Ώۓ��̑O�N��N�x�Ƃ���
        lv_calendar_code := TO_CHAR(TO_NUMBER(lv_calendar_code) - 1);
      END IF;
      --
      SELECT SUM(TO_NUMBER(ccd.cmpnt_cost)) AS cmpnt_cost
      INTO   ov_cmpnt_cost
      FROM   cm_cmpt_dtl              ccd
            ,ic_item_mst_b            cimb
            ,mtl_system_items_b       msib
      WHERE  ccd.item_id            = cimb.item_id
      AND    ccd.calendar_code      = lv_calendar_code
      AND    cimb.item_no           = msib.segment1
      AND    msib.inventory_item_id = in_item_id
      AND    msib.organization_id   = in_org_id;
    END IF;
    --
    IF (ov_cmpnt_cost IS NULL) THEN
      ov_retcode    := cv_status_error; -- �ُ�:2
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_cmpnt_cost := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_cmpnt_cost;
/************************************************************************
 * Procedure Name  : GET_DISCRETE_COST
 * Description     : �i��ID�����Ɋm��ς݂̉c�ƌ������擾���܂��B
 ************************************************************************/
  PROCEDURE get_discrete_cost(
    in_item_id        IN  NUMBER             -- �i��ID
   ,in_org_id         IN  NUMBER             -- �g�DID
   ,id_target_date    IN  DATE               -- �Ώۓ�
   ,ov_discrete_cost  OUT VARCHAR2           -- �c�ƌ���
   ,ov_errbuf         OUT VARCHAR2           -- �G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2           -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg         OUT VARCHAR2           -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    cv_prg_name  CONSTANT VARCHAR2(99) := 'get_discrete_cost';
  BEGIN
    IF (in_item_id      IS NULL
      OR in_org_id      IS NULL
      OR id_target_date IS NULL) THEN
      ov_retcode := cv_status_error;         -- �ُ�:2
    ELSE
      ov_retcode := cv_status_normal;        -- ����:0
      BEGIN
        SELECT CASE
               WHEN imb.attribute9 <= TO_CHAR(id_target_date,'YYYY/MM/DD') -- �c�ƌ����K�p�J�n��
               THEN imb.attribute8                                  -- �c�ƌ���(�V)
               ELSE imb.attribute7                                  -- ���c�ƌ���
               END  AS discrete_cost
        INTO   ov_discrete_cost
        FROM   mtl_system_items_b     sib                           -- Disc�i�ڃ}�X�^
              ,ic_item_mst_b          imb                           -- OPM�i�ڃ}�X�^
        WHERE  sib.organization_id               = in_org_id        -- �c�ƃV�X�e���̍݌ɑg�DID
          AND  sib.inventory_item_id             = in_item_id       -- �Ώەi��ID
          AND  sib.inventory_item_status_code   <> 'Inactive'       -- �i�ڃX�e�[�^�X�F�S�@�\�g�p�\
          AND  sib.customer_order_enabled_flag   = 'Y'              -- �ڋq�󒍉\�t���O
          AND  sib.mtl_transactions_enabled_flag = 'Y'              -- ����\
          AND  sib.stock_enabled_flag            = 'Y'              -- �݌ɕۗL�\�t���O
          AND  sib.returnable_flag               = 'Y'              -- �ԕi�\
          AND  imb.item_no                       = sib.segment1     -- �i���R�[�h
          AND  imb.attribute26                   = '1';             -- ����Ώۋ敪
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SELECT cic.item_cost AS item_cost
          INTO   ov_discrete_cost
          FROM   cst_item_costs          cic -- Disc�i�ڌ���
          WHERE  cic.inventory_item_id = in_item_id
          AND    cic.organization_id   = in_org_id
          AND    cic.cost_type_id      = 1;  -- �m���
      END;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_discrete_cost := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_discrete_cost;
/************************************************************************
 * Function Name   : GET_TRANSACTION_TYPE_ID
 * Description     : ����^�C�v�������ƂɁA����^�C�vID���擾
 ************************************************************************/
  FUNCTION  get_transaction_type_id(
    iv_transaction_type_name IN VARCHAR2     -- ����^�C�v��
  ) RETURN NUMBER
  IS
    ln_transaction_type_id NUMBER;
  BEGIN
    BEGIN
      SELECT mtt.transaction_type_id AS transaction_type_id
      INTO   ln_transaction_type_id
      FROM   mtl_transaction_types mtt
      WHERE  NVL(mtt.disable_date,SYSDATE) >= SYSDATE
      AND    mtt.transaction_type_name      = iv_transaction_type_name;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_transaction_type_id;
  END get_transaction_type_id;
/************************************************************************
 * Function Name   : GET_ITEM_CODE
 * Description     : �i��ID�����Ƃɕi�ڃR�[�h���擾����B
 ************************************************************************/
  FUNCTION get_item_code(
    in_item_id    IN NUMBER             -- �i��ID
   ,in_org_id     IN NUMBER             -- �g�DID
  ) RETURN VARCHAR2
  IS
    lv_item_code VARCHAR2(40) := NULL;  -- �i�ڃR�[�h
  BEGIN
    BEGIN
      SELECT msib.segment1 AS item_code
      INTO   lv_item_code
      FROM   mtl_system_items_b msib
      WHERE  msib.inventory_item_id = in_item_id
      AND    msib.organization_id   = in_org_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN lv_item_code;
  END get_item_code;
--
/************************************************************************
 * Procedure Name  : get_item_info
 * Description     : �i�ڃ`�F�b�N�Ɏg�p����i�ڕt�������擾���܂��B
 ************************************************************************/
  PROCEDURE get_item_info(
    ov_errbuf               OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode              OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg               OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_item_code            IN  VARCHAR2   -- 4.�i�ڃR�[�h
   ,in_org_id               IN  NUMBER     -- 5.�݌ɑg�DID
   ,ov_item_status          OUT VARCHAR2   -- 6.�i�ڃX�e�[�^�X
   ,ov_cust_order_flg       OUT VARCHAR2   -- 7.�ڋq�󒍉\�t���O
   ,ov_transaction_enable   OUT VARCHAR2   -- 8.����\
   ,ov_stock_enabled_flg    OUT VARCHAR2   -- 9.�݌ɕۗL�\�t���O
   ,ov_return_enable        OUT VARCHAR2   -- 10.�ԕi�\
   ,ov_sales_class          OUT VARCHAR2   -- 11.����Ώۋ敪
   ,ov_primary_unit         OUT VARCHAR2   -- 12.��P��
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'get_item_info';   -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';              -- �A�v���P�[�V�����Z�k��
--
    cv_msg_coi_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- �Ώۃf�[�^�������b�Z�[�W
    cv_msg_coi_00025       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00025';   -- �������擾�G���[
    cv_msg_coi_10258       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10258';   -- ���̓p�����[�^���ݒ�G���[�i�i�ڃR�[�h�j
    cv_msg_coi_10259       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10259';   -- ���̓p�����[�^���ݒ�G���[�i�݌ɑg�DID�j
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J����O ***
    no_parameter_expt   EXCEPTION;   -- �p�����[�^���ݒ�G���[
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- IN�p�����[�^�`�F�b�N
    -- ====================================================
    -- �i�ڃR�[�h�����ݒ�̏ꍇ
    IF (iv_item_code IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10258);
      RAISE no_parameter_expt;
    END IF;
--
    -- �݌ɑg�DID�����ݒ�̏ꍇ
    IF (in_org_id IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10259);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- �i�ڏ�� �擾
    -- ====================================================
    SELECT msib.inventory_item_status_code    AS inventory_item_status_code      -- 1.�i�ڃX�e�[�^�X
          ,msib.customer_order_enabled_flag   AS customer_order_enabled_flag     -- 2.�ڋq�󒍉\�t���O
          ,msib.mtl_transactions_enabled_flag AS mtl_transactions_enabled_flag   -- 3.����\
          ,msib.stock_enabled_flag            AS stock_enabled_flag              -- 4.�݌ɕۗL�\�t���O
          ,msib.returnable_flag               AS returnable_flag                 -- 5.�ԕi�\
          ,iimb.attribute26                   AS attribute26                     -- 6.����Ώۋ敪
          ,msib.primary_unit_of_measure       AS primary_unit_of_measure         -- 7.��P��
    INTO   ov_item_status            -- 1.�i�ڃX�e�[�^�X
          ,ov_cust_order_flg         -- 2.�ڋq�󒍉\�t���O
          ,ov_transaction_enable     -- 3.����\
          ,ov_stock_enabled_flg      -- 4.�݌ɕۗL�\�t���O
          ,ov_return_enable          -- 5.�ԕi�\
          ,ov_sales_class            -- 6.����Ώۋ敪
          ,ov_primary_unit           -- 7.��P��
    FROM   mtl_system_items_b msib   -- 1.Disc�i�ڃ}�X�^
          ,ic_item_mst_b      iimb   -- 2.OPM�i�ڃ}�X�^
    WHERE  msib.segment1        = iv_item_code
    AND    msib.organization_id = in_org_id
    AND    iimb.item_no         = msib.segment1;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                  -- *** �擾�����Ȃ��G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00008);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** �������擾�G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** �p�����[�^���ݒ�G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_item_info;
--
--
/************************************************************************
 * Procedure Name  : get_item_info2
 * Description     : �i�ڃ`�F�b�N�Ɏg�p����i�ڕt�������擾���܂��B
 ************************************************************************/
  PROCEDURE get_item_info2(
    ov_errbuf               OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode              OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg               OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_item_code            IN  VARCHAR2   -- 4.�i�ڃR�[�h
   ,in_org_id               IN  NUMBER     -- 5.�݌ɑg�DID
   ,ov_item_status          OUT VARCHAR2   -- 6.�i�ڃX�e�[�^�X
   ,ov_cust_order_flg       OUT VARCHAR2   -- 7.�ڋq�󒍉\�t���O
   ,ov_transaction_enable   OUT VARCHAR2   -- 8.����\
   ,ov_stock_enabled_flg    OUT VARCHAR2   -- 9.�݌ɕۗL�\�t���O
   ,ov_return_enable        OUT VARCHAR2   -- 10.�ԕi�\
   ,ov_sales_class          OUT VARCHAR2   -- 11.����Ώۋ敪
   ,ov_primary_unit         OUT VARCHAR2   -- 12.��P��
   ,on_inventory_item_id    OUT NUMBER     -- 13.�i��ID
   ,ov_primary_uom_code     OUT VARCHAR2   -- 14.��P�ʃR�[�h
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'get_item_info';   -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';              -- �A�v���P�[�V�����Z�k��
--
    cv_msg_coi_10368       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10368';   -- �i�ڎ擾��O���b�Z�[�W
    cv_msg_coi_10369       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10369';   -- �i�ڕ������擾�G���[
    cv_msg_coi_10258       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10258';   -- ���̓p�����[�^���ݒ�G���[�i�i�ڃR�[�h�j
    cv_msg_coi_10259       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10259';   -- ���̓p�����[�^���ݒ�G���[�i�݌ɑg�DID�j
    --
    cv_tkn_item_code       CONSTANT VARCHAR2(9)  := 'ITEM_CODE';          -- TKN:IETM_CODE
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J����O ***
    no_parameter_expt   EXCEPTION;   -- �p�����[�^���ݒ�G���[
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- IN�p�����[�^�`�F�b�N
    -- ====================================================
    -- �i�ڃR�[�h�����ݒ�̏ꍇ
    IF (iv_item_code IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10258);
      RAISE no_parameter_expt;
    END IF;
--
    -- �݌ɑg�DID�����ݒ�̏ꍇ
    IF (in_org_id IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10259);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- �i�ڏ�� �擾
    -- ====================================================
    SELECT msib.inventory_item_status_code    AS inventory_item_status_code      -- 1.�i�ڃX�e�[�^�X
          ,msib.customer_order_enabled_flag   AS customer_order_enabled_flag     -- 2.�ڋq�󒍉\�t���O
          ,msib.mtl_transactions_enabled_flag AS mtl_transactions_enabled_flag   -- 3.����\
          ,msib.stock_enabled_flag            AS stock_enabled_flag              -- 4.�݌ɕۗL�\�t���O
          ,msib.returnable_flag               AS returnable_flag                 -- 5.�ԕi�\
          ,iimb.attribute26                   AS attribute26                     -- 6.����Ώۋ敪
          ,msib.primary_unit_of_measure       AS primary_unit_of_measure         -- 7.��P��
          ,msib.inventory_item_id             AS inventory_item_id               -- 8.�i��ID
          ,msib.primary_uom_code              AS primary_uom_code                -- 9.��P�ʃR�[�h
    INTO   ov_item_status            -- 1.�i�ڃX�e�[�^�X
          ,ov_cust_order_flg         -- 2.�ڋq�󒍉\�t���O
          ,ov_transaction_enable     -- 3.����\
          ,ov_stock_enabled_flg      -- 4.�݌ɕۗL�\�t���O
          ,ov_return_enable          -- 5.�ԕi�\
          ,ov_sales_class            -- 6.����Ώۋ敪
          ,ov_primary_unit           -- 7.��P��
          ,on_inventory_item_id      -- 8.�i��ID
          ,ov_primary_uom_code       -- 9.��P�ʃR�[�h
    FROM   mtl_system_items_b msib   -- 1.Disc�i�ڃ}�X�^
          ,ic_item_mst_b      iimb   -- 2.OPM�i�ڃ}�X�^
    WHERE  msib.segment1        = iv_item_code
    AND    msib.organization_id = in_org_id
    AND    iimb.item_no         = msib.segment1;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                  -- *** �擾�����Ȃ��G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10368
                     ,iv_token_name1  => cv_tkn_item_code
                     ,iv_token_value1 => iv_item_code
                      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** �������擾�G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10369
                     ,iv_token_name1  => cv_tkn_item_code
                     ,iv_token_value1 => iv_item_code
                      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** �p�����[�^���ݒ�G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_item_info2;
--
/************************************************************************
 * Procedure Name  : get_uom_disable_info
 * Description     : �P�ʃ}�X�^���P�ʂ̖��������擾���܂��B
 ************************************************************************/
  PROCEDURE get_uom_disable_info(
    ov_errbuf         OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg         OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_unit_code      IN  VARCHAR2   -- 4.�P�ʃR�[�h
   ,od_disable_date   OUT DATE       -- 5.������
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_uom_disable_info'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';   -- �A�v���P�[�V�����Z�k��
--
    cv_msg_coi_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- �Ώۃf�[�^�������b�Z�[�W
    cv_msg_coi_00025       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00025';   -- �������擾�G���[
    cv_msg_coi_10260       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10260';   -- ���̓p�����[�^���ݒ�G���[�i�P�ʃR�[�h�j
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J����O ***
    no_parameter_expt   EXCEPTION;   -- �p�����[�^���ݒ�G���[
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- IN�p�����[�^�`�F�b�N
    -- ====================================================
    -- �P�ʃR�[�h�����ݒ�̏ꍇ
    IF (iv_unit_code IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10260);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- ������ �擾
    -- ====================================================
    SELECT muomt.disable_date AS disable_date   -- 1.������
    INTO   od_disable_date                      -- 1.������
    FROM   mtl_units_of_measure_tl muomt        -- 1.�P�ʃ}�X�^
    WHERE  muomt.uom_code = iv_unit_code
    AND    muomt.language = USERENV('LANG');
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                  -- *** �擾�����Ȃ��G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00008);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** �������擾�G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** �p�����[�^���ݒ�G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_uom_disable_info;
--
/************************************************************************
 * Procedure Name  : get_subinventory_info1
 * Description     : �ۊǏꏊ�}�X�^���A���_�R�[�h�E�q�ɃR�[�h�����
 *                   �ۊǏꏊ�R�[�h�Ɩ��������擾���܂��B
 ************************************************************************/
  PROCEDURE get_subinventory_info1(
    ov_errbuf         OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg         OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code      IN  VARCHAR2   -- 4.���_�R�[�h
   ,iv_whse_code      IN  VARCHAR2   -- 5.�q�ɃR�[�h
   ,ov_sec_inv_nm     OUT VARCHAR2   -- 6.�ۊǏꏊ�R�[�h
   ,od_disable_date   OUT DATE       -- 7.������
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_subinventory_info1'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';   -- �A�v���P�[�V�����Z�k��
--
    cv_msg_coi_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- �Ώۃf�[�^�������b�Z�[�W
    cv_msg_coi_00025       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00025';   -- �������擾�G���[
    cv_msg_coi_10261       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10261';   -- ���̓p�����[�^���ݒ�G���[�i���_�R�[�h�j
    cv_msg_coi_10262       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10262';   -- ���̓p�����[�^���ݒ�G���[�i�q�ɃR�[�h�j
--
    cv_whse_code_whse      CONSTANT VARCHAR2(1) := '1';   -- �q��
-- add 2009/03/13 1.1 H.Wada #T1_0040 ��
    cv_whse_code_store     CONSTANT VARCHAR2(1) := '4';   -- ���X
-- add 2009/03/13 1.1 H.Wada #T1_0040 ��
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J����O ***
    no_parameter_expt      EXCEPTION;   -- �p�����[�^���ݒ�G���[
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- IN�p�����[�^�`�F�b�N
    -- ====================================================
    -- ���_�R�[�h�����ݒ�̏ꍇ
    IF (iv_base_code IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10261);
      RAISE no_parameter_expt;
    END IF;
    -- �q�ɃR�[�h�����ݒ�̏ꍇ
    IF (iv_whse_code IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10262);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- �ۊǏꏊ��� �擾
    -- ====================================================
    SELECT msi.secondary_inventory_name AS secondary_inventory_name   -- 1.�ۊǏꏊ�R�[�h
          ,msi.disable_date             AS disable_date               -- 2.������
    INTO   ov_sec_inv_nm     -- 1.�ۊǏꏊ�R�[�h
          ,od_disable_date   -- 2.������
    FROM   mtl_secondary_inventories msi   -- 1.�ۊǏꏊ�}�X�^
    WHERE  msi.attribute7 = iv_base_code
    AND    SUBSTRB(msi.secondary_inventory_name,6 ,2) = iv_whse_code
    AND    msi.attribute1 IN (cv_whse_code_whse, cv_whse_code_store);
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                  -- *** �擾�����Ȃ��G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00008);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** �������擾�G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** �p�����[�^���ݒ�G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_subinventory_info1;
--
--
/************************************************************************
 * Procedure Name  : get_subinventory_info2
 * Description     : �ۊǏꏊ�}�X�^���A���_�R�[�h�E�X�܃R�[�h�����
 *                   �ۊǏꏊ�R�[�h�Ɩ��������擾���܂��B
 ************************************************************************/
  PROCEDURE get_subinventory_info2(
    ov_errbuf         OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg         OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code      IN  VARCHAR2   -- 4.���_�R�[�h
   ,iv_shop_code      IN  VARCHAR2   -- 5.�X�܃R�[�h
   ,ov_sec_inv_nm     OUT VARCHAR2   -- 6.�ۊǏꏊ�R�[�h
   ,od_disable_date   OUT DATE       -- 7.������
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_subinventory_info2'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';   -- �A�v���P�[�V�����Z�k��
--
    cv_msg_coi_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- �Ώۃf�[�^�������b�Z�[�W
    cv_msg_coi_00025       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00025';   -- �������擾�G���[
    cv_msg_coi_10261       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10261';   -- ���̓p�����[�^���ݒ�G���[�i���_�R�[�h�j
    cv_msg_coi_10263       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10263';   -- ���̓p�����[�^���ݒ�G���[�i�X�܃R�[�h�j
--
    cv_deposit_point       CONSTANT VARCHAR2(1) := '3';   -- �a����
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J����O ***
    no_parameter_expt      EXCEPTION;   -- �p�����[�^���ݒ�G���[
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- IN�p�����[�^�`�F�b�N
    -- ====================================================
    -- ���_�R�[�h�����ݒ�̏ꍇ
    IF (iv_base_code IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10261);
      RAISE no_parameter_expt;
    END IF;
    -- �X�܃R�[�h�����ݒ�̏ꍇ
    IF (iv_shop_code IS NULL) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10263);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- �ۊǏꏊ��� �擾
    -- ====================================================
    SELECT msi.secondary_inventory_name AS secondary_inventory_name   -- 1.�ۊǏꏊ�R�[�h
          ,msi.disable_date             AS disable_date               -- 2.������
    INTO   ov_sec_inv_nm     -- 1.�ۊǏꏊ�R�[�h
          ,od_disable_date   -- 2.������
    FROM   mtl_secondary_inventories msi   -- 1.�ۊǏꏊ�}�X�^
    WHERE  msi.attribute7 = iv_base_code
    AND    SUBSTRB(msi.secondary_inventory_name,6 ,5) = iv_shop_code
    AND    msi.attribute1 = cv_deposit_point;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN  -- *** �擾�����Ȃ��G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00008);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** �������擾�G���[ ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** �p�����[�^�K�{�G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_subinventory_info2;
--
--
/************************************************************************
 * Function Name   : GET_MANAGE_DEPT_F
 * Description     : �����_���Ǘ��ۂ��P�Ƌ��_�Ȃ̂��𔻕ʂ���t���O���擾����B
 *                   �߂�l�F0�i�P�Ƌ��_�j�A1�i�Ǘ��ہj
 ************************************************************************/
  FUNCTION get_manage_dept_f(
    iv_base_code   IN   VARCHAR2   -- 1.���_�R�[�h
  ) RETURN NUMBER   -- �Ǘ��۔��ʃt���O
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_manage_dept_f'; -- �v���O������
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_class_code_base   CONSTANT VARCHAR2(10) := '1';   -- ���_
    cv_status            CONSTANT VARCHAR2(1)  := 'A';   -- �X�e�[�^�X
    cn_sole_base         CONSTANT NUMBER       := 0;     -- �P�Ƌ��_
    cn_manage_section    CONSTANT NUMBER       := 1;     -- �Ǘ���
    --
    -- *** ���[�J���ϐ� ***
    lt_account_number         hz_cust_accounts.account_number%TYPE;            -- 1.�ڋq�R�[�h
    lt_management_base_code   xxcmm_cust_accounts.management_base_code%TYPE;   -- 2.�Ǘ������_�R�[�h
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
    -- ====================================================
    -- IN�p�����[�^�`�F�b�N
    -- ====================================================
    -- ���_�R�[�h�����ݒ�̏ꍇ
    IF (iv_base_code IS NULL) THEN
      RETURN NULL;
    END IF;
    --
    -- ====================================================
    -- �ڋq��� �擾
    -- ====================================================
    SELECT hca.account_number         -- 1.�ڋq�R�[�h
          ,xca.management_base_code   -- 2.�Ǘ������_�R�[�h
    INTO   lt_account_number          -- 1.�ڋq�R�[�h
          ,lt_management_base_code    -- 2.�Ǘ������_�R�[�h
    FROM   hz_cust_accounts    hca    -- 1.�ڋq�A�J�E���g
          ,xxcmm_cust_accounts xca    -- 2.�ڋq�ǉ����A�h�I��
    WHERE  hca.account_number = iv_base_code
    AND    xca.customer_id = hca.cust_account_id
    AND    hca.customer_class_code = cv_class_code_base
    AND    hca.STATUS = cv_status;
    --
    -- ====================================================
    -- �ڋq���`�F�b�N
    -- ====================================================
    -- �Ǘ������_�R�[�h�����ݒ�̏ꍇ
    IF (lt_management_base_code IS NULL) THEN
      RETURN cn_sole_base;
    -- �ڋq�R�[�h���Ǘ������_�R�[�h�̏ꍇ
    ELSIF (lt_account_number <> lt_management_base_code) THEN
      RETURN cn_sole_base;
    -- �ڋq�R�[�h���Ǘ������_�R�[�h�̏ꍇ
    ELSIF (lt_account_number = lt_management_base_code) THEN
      RETURN cn_manage_section;
    ELSE
      RETURN NULL;
    END IF;
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                      -- *** �擾�����Ȃ��G���[ ***
      RETURN NULL;
    --
  END get_manage_dept_f;
--
/************************************************************************
 * Function Name   : get_lookup_values
 * Description     : �N�C�b�N�R�[�h�}�X�^�̊e���ڒl�����R�[�h�^�Ŏ擾����B
 ************************************************************************/
  FUNCTION get_lookup_values(
    iv_lookup_type    IN  VARCHAR2
   ,iv_lookup_code    IN  VARCHAR2
   ,id_enabled_date   IN  DATE      DEFAULT SYSDATE
  ) RETURN lookup_rec
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lookup_values'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lr_lookup_values        lookup_rec;     -- �N�C�b�N�R�[�h�}�X�^���i�[���R�[�h
    ld_sysdate              DATE;           -- �V�X�e�����t
    ld_param_enabled_date   DATE;           -- �y���̓p�����[�^�z�L����
    --
  BEGIN
    -- ����������
    lr_lookup_values      :=  NULL;
    ld_sysdate            :=  TRUNC(SYSDATE);
    ld_param_enabled_date :=  TRUNC(id_enabled_date);
    --
    IF (ld_sysdate = ld_param_enabled_date) THEN
      -- �y���̓p�����[�^�z�L�������A�V�X�e�����t�ƈ�v����ꍇ
      SELECT  flv.meaning     AS meaning          -- ���e
             ,flv.description AS description      -- �E�v
             ,flv.attribute1  AS attribute1       -- DFF1
             ,flv.attribute2  AS attribute2       -- DFF2
             ,flv.attribute3  AS attribute3       -- DFF3
             ,flv.attribute4  AS attribute4       -- DFF4
             ,flv.attribute5  AS attribute5       -- DFF5
             ,flv.attribute6  AS attribute6       -- DFF6
             ,flv.attribute7  AS attribute7       -- DFF7
             ,flv.attribute8  AS attribute8       -- DFF8
             ,flv.attribute9  AS attribute9       -- DFF9
             ,flv.attribute10 AS attribute10      -- DFF10
             ,flv.attribute11 AS attribute11      -- DFF11
             ,flv.attribute12 AS attribute12      -- DFF12
             ,flv.attribute13 AS attribute13      -- DFF13
             ,flv.attribute14 AS attribute14      -- DFF14
             ,flv.attribute15 AS attribute15      -- DFF15
      INTO    lr_lookup_values.meaning
             ,lr_lookup_values.description
             ,lr_lookup_values.attribute1
             ,lr_lookup_values.attribute2
             ,lr_lookup_values.attribute3
             ,lr_lookup_values.attribute4
             ,lr_lookup_values.attribute5
             ,lr_lookup_values.attribute6
             ,lr_lookup_values.attribute7
             ,lr_lookup_values.attribute8
             ,lr_lookup_values.attribute9
             ,lr_lookup_values.attribute10
             ,lr_lookup_values.attribute11
             ,lr_lookup_values.attribute12
             ,lr_lookup_values.attribute13
             ,lr_lookup_values.attribute14
             ,lr_lookup_values.attribute15
      FROM    fnd_lookup_values     flv           -- LOOKUP�\
      WHERE   flv.lookup_type   =   iv_lookup_type
      AND     flv.lookup_code   =   iv_lookup_code
      AND     flv.language      =   USERENV('LANG')
      AND     flv.enabled_flag  =   'Y'
      AND     ld_sysdate BETWEEN NVL(flv.start_date_active, ld_sysdate)
                         AND     NVL(flv.end_date_active,   ld_sysdate);
      --
    ELSE
      -- �y���̓p�����[�^�z�L�������A�V�X�e�����t�ƈ�v���Ȃ��ꍇ
      SELECT  flv.meaning     AS meaning          -- ���e
             ,flv.description AS description      -- �E�v
             ,flv.attribute1  AS attribute1       -- DFF1
             ,flv.attribute2  AS attribute2       -- DFF2
             ,flv.attribute3  AS attribute3       -- DFF3
             ,flv.attribute4  AS attribute4       -- DFF4
             ,flv.attribute5  AS attribute5       -- DFF5
             ,flv.attribute6  AS attribute6       -- DFF6
             ,flv.attribute7  AS attribute7       -- DFF7
             ,flv.attribute8  AS attribute8       -- DFF8
             ,flv.attribute9  AS attribute9       -- DFF9
             ,flv.attribute10 AS attribute10      -- DFF10
             ,flv.attribute11 AS attribute11      -- DFF11
             ,flv.attribute12 AS attribute12      -- DFF12
             ,flv.attribute13 AS attribute13      -- DFF13
             ,flv.attribute14 AS attribute14      -- DFF14
             ,flv.attribute15 AS attribute15      -- DFF15
      INTO    lr_lookup_values.meaning
             ,lr_lookup_values.description
             ,lr_lookup_values.attribute1
             ,lr_lookup_values.attribute2
             ,lr_lookup_values.attribute3
             ,lr_lookup_values.attribute4
             ,lr_lookup_values.attribute5
             ,lr_lookup_values.attribute6
             ,lr_lookup_values.attribute7
             ,lr_lookup_values.attribute8
             ,lr_lookup_values.attribute9
             ,lr_lookup_values.attribute10
             ,lr_lookup_values.attribute11
             ,lr_lookup_values.attribute12
             ,lr_lookup_values.attribute13
             ,lr_lookup_values.attribute14
             ,lr_lookup_values.attribute15
      FROM    fnd_lookup_values     flv           -- LOOKUP�\
      WHERE   flv.lookup_type   =   iv_lookup_type
      AND     flv.lookup_code   =   iv_lookup_code
      AND     flv.language      =   USERENV('LANG')
      AND     ld_param_enabled_date BETWEEN NVL(flv.start_date_active, ld_param_enabled_date)
                                    AND     NVL(flv.end_date_active,   ld_param_enabled_date);
      --
    END IF;
    --
    RETURN  lr_lookup_values;
--
  EXCEPTION
    WHEN OTHERS THEN
      -- �S����NULL�ŕԋp
      RETURN  lr_lookup_values;
--
  END get_lookup_values;
--
/************************************************************************
 * Procedure Name  : CONVERT_WHOUSE_SUBINV_CODE
 * Description     : HHT�q�ɕۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_whouse_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code                    IN         VARCHAR2   -- 4.���_�R�[�h
   ,iv_warehouse_code               IN         VARCHAR2   -- 5.�q�ɃR�[�h
   ,in_organization_id              IN         NUMBER     -- 6.�݌ɑg�DID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 7.�ۊǏꏊ�R�[�h
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 8.���_�R�[�h
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 9.�I���Ώ�
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'convert_whouse_subinv_code';     -- �v���O������
    -- *** ���[�J���萔 ***
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';                        -- �A�v���P�[�V�����Z�k��
    cv_msg_coi_10206       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10206';             -- MSG�F�ۊǏꏊ�擾�G���[
    cv_msg_coi_10207       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10207';             -- MSG�F�ۊǏꏊ�����G���[
    cv_tkn_subinv_code     CONSTANT VARCHAR2(13) := 'SUB_INV_CODE';                 -- TKN�F�ۊǏꏊ����
    cv_warehouse_div       CONSTANT VARCHAR2(1)  := 'A';                            -- �q�Ɏ��ʎq
    -- *** ���[�J���ϐ� ***
    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;            -- �ۊǏꏊ������
    -- *** ���[�J����O ***
    disable_date_expt       EXCEPTION;                                              -- �ۊǏꏊ�������G���[
  --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    SELECT 
             msi.secondary_inventory_name   AS secondary_inventory_name -- 1.�ۊǏꏊ�R�[�h
            ,msi.attribute7                 AS base_code                -- 2.���_�R�[�h
            ,msi.disable_date               AS disable_date             -- 3.������
            ,msi.attribute5                 AS subinv_div               -- 4.�I���Ώ�
    INTO
             ov_subinv_code                                             -- 1.�ۊǏꏊ�R�[�h
            ,ov_base_code                                               -- 2.���_�R�[�h
            ,lt_disable_date                                            -- 3.������
            ,ov_subinv_div                                              -- 4.�I���Ώ�
    FROM    mtl_secondary_inventories msi 
    WHERE   msi.secondary_inventory_name    = cv_warehouse_div||iv_base_code||iv_warehouse_code
    AND     msi.organization_id             = in_organization_id;
    --
    IF lt_disable_date IS NOT NULL 
        AND TRUNC(lt_disable_date) <= TRUNC(SYSDATE) 
    THEN
    --
        RAISE disable_date_expt;
    --
    END IF;
  --
  EXCEPTION
  --
    WHEN disable_date_expt THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_kbn_coi
                  ,iv_name         => cv_msg_coi_10207
                  ,iv_token_name1  => cv_tkn_subinv_code
                  ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN NO_DATA_FOUND THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10206
                        ,iv_token_name1  => cv_tkn_subinv_code
                        ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10206
                        ,iv_token_name1  => cv_tkn_subinv_code
                        ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END convert_whouse_subinv_code;
/************************************************************************
 * Procedure Name  : CONVERT_EMP_SUBINV_CODE
 * Description     : HHT�c�ƎԕۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_emp_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code                    IN         VARCHAR2   -- 4.���_�R�[�h
   ,iv_employee_number              IN         VARCHAR2   -- 5.�]�ƈ��R�[�h
   ,id_transaction_date             IN         DATE       -- 6.�`�[���t
   ,in_organization_id              IN         NUMBER     -- 7.�݌ɑg�DID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 8.�ۊǏꏊ�R�[�h
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 9.���_�R�[�h
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   --10.�I���Ώ�
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'convert_emp_subinv_code';     -- �v���O������
    -- *** ���[�J���萔 ***
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi          CONSTANT VARCHAR2(5)  := 'XXCOI';               -- �A�v���P�[�V�����Z�k��
    cv_dummy_code          CONSTANT VARCHAR2(2) := '99';                    -- �_�~�[�R�[�h
    cv_cust_class_base     CONSTANT VARCHAR2(1) := '1';                     -- �ڋq�敪�F���_
    cv_dept_hht_single_div CONSTANT VARCHAR2(1) := '2';                     -- �S�ݓXHHT�敪�F���_�P
    cv_dept_hht_double_div CONSTANT VARCHAR2(1) := '1';                     -- �S�ݓXHHT�敪�F���_��
    cv_employee            CONSTANT VARCHAR2(8) := 'EMPLOYEE';              -- �J�e�S���F�]�ƈ�
    cv_sub_inv_type_car           CONSTANT VARCHAR2(1) := '5';                     -- �ۊǏꏊ���ށF�c�Ǝ�
    --
    cv_msg_coi_10204       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10204';     -- MSG�F�S�ݓXHHT�敪�擾�G���[
    cv_msg_coi_10208       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10208';     -- MSG�F�������_�擾�G���[
    cv_msg_coi_10209       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10209';     -- MSG�F�������_���ݒ�G���[
    cv_msg_coi_10217       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10217';     -- MSG�F�Ǘ������_�s��v�G���[
    cv_msg_coi_10212       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10212';     -- MSG�F�c�ƎԕۊǏꏊ�擾�G���[
    cv_msg_coi_10213       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10213';     -- MSG�F�c�ƎԕۊǏꏊ�����G���[
    cv_msg_coi_10253       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10253';     -- MSG�F�c�ƎԕۊǏꏊ�d���G���[
    cv_tkn_employee_code   CONSTANT VARCHAR2(13) := 'EMPLOYEE_CODE';        -- TKN�F�c�ƈ�����
    cv_tkn_dept_code       CONSTANT VARCHAR2(13) := 'DEPT_CODE';            -- TKN�F���_����
    --
    -- *** ���[�J���ϐ� ***
    lt_dept_hht_div         xxcmm_cust_accounts.dept_hht_div%TYPE;          -- �S�ݓX�pHHT�敪
    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;    -- �ۊǏꏊ������
    lt_salesrep_number      jtf_rs_salesreps.salesrep_number%TYPE;          -- �c�ƈ��R�[�h
    lt_belong_base_code     hz_cust_accounts.account_number%TYPE;           -- �������_�R�[�h
    ln_base_count           NUMBER := 0;                                    -- �Ǘ������_��v����
    -- *** ���[�J����O ***
    sub_error_expt          EXCEPTION;                                         -- �T�u��`��O�G���[
    sub_others_error_expt   EXCEPTION;                                         -- �T�u��`Oters��O�G���[
  --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
    -- ====================================================
    -- 1.�S�ݓX�pHHT�敪 �擾
    -- ====================================================
    --
    BEGIN
    --
        SELECT 
                NVL(xca.dept_hht_div,cv_dept_hht_single_div) AS dept_hht_div    -- 1.�S�ݓX�pHHT�敪
        INTO   
                lt_dept_hht_div                                                 -- 1.�S�ݓX�pHHT�敪
        FROM   
                hz_cust_accounts hca
               ,xxcmm_cust_accounts xca
        WHERE  
                hca.cust_account_id     = xca.customer_id
        AND     hca.account_number      = iv_base_code
        AND     hca.customer_class_code = cv_cust_class_base;
    --
    EXCEPTION
    --
        WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10204
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_error_expt;
        --
        WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10204
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_others_error_expt;
    --
    END;
    -- ================================================
    -- 2.�S�ݓXHHT�敪�F���_��
    -- ================================================
    IF lt_dept_hht_div = cv_dept_hht_double_div THEN
        -- ========================================
        -- 2-1.�c�ƈ��R�[�h�A�]�ƈ��̏������_���擾
        -- ========================================
        BEGIN
        --
            SELECT  
                    jrs.salesrep_number                 AS salesrep_number  -- 1.�c�ƈ��R�[�h
                    ,CASE WHEN TRUNC(id_transaction_date) < TRUNC(to_date(paf.ass_attribute2,'yyyymmdd')) 
                            THEN NVL(paf.ass_attribute6,cv_dummy_code)
                          WHEN TRUNC(id_transaction_date) >= TRUNC(to_date(paf.ass_attribute2,'yyyymmdd')) 
                            THEN NVL(paf.ass_attribute5,cv_dummy_code)
                          ELSE cv_dummy_code END        AS dept_code        -- 2.�������_�R�[�h
            INTO
                    lt_salesrep_number                                      -- 1.�c�ƈ��R�[�h
                    ,lt_belong_base_code                                    -- 2.�������_�R�[�h
            FROM    per_all_people_f ppf
                    ,per_all_assignments_f paf
                    ,jtf_rs_salesreps jrs
                    ,jtf_rs_resource_extns jrre
            WHERE   ppf.person_id       = paf.person_id
            AND     TRUNC(cd_business_date) 
                      BETWEEN TRUNC(ppf.effective_start_date )
                          AND TRUNC( NVL( ppf.effective_end_date , cd_business_date) )
            AND     TRUNC(cd_business_date) 
                      BETWEEN TRUNC(paf.effective_start_date )
                          AND TRUNC( NVL( paf.effective_end_date , cd_business_date ) )
            AND     ppf.person_id       = jrre.source_id
            AND     jrre.category       = cv_employee
            AND     jrre.resource_id    = jrs.resource_id
            AND     ppf.employee_number = iv_employee_number;
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10208
                                ,iv_token_name1  => cv_tkn_employee_code
                                ,iv_token_value1 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
        --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10208
                                ,iv_token_name1  => cv_tkn_employee_code
                                ,iv_token_value1 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_others_error_expt;
        --
        END;
        -- ========================================
        -- 2-2.�V/�����_�R�[�h�̖��ݒ�A���ߓ��̖��ݒ��O
        -- ========================================
        IF lt_belong_base_code = cv_dummy_code THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10209
                      ,iv_token_name1  => cv_tkn_employee_code
                      ,iv_token_value1 => iv_employee_number
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
        -- ========================================
        -- 2-3.�Ǘ������_�̈�v�`�F�b�N
        -- ========================================
        --
        SELECT
              COUNT(1) AS COUNT             -- 1.�Ǘ������_�̈�v����
        INTO
              ln_base_count                 -- 1.�Ǘ������_�̈�v����
        FROM
              hz_cust_accounts hca
             ,xxcmm_cust_accounts xca
        WHERE
              hca.cust_account_id       = xca.customer_id
        AND   hca.customer_class_code   = cv_cust_class_base
        AND   hca.account_number        = lt_belong_base_code
        AND   xca.management_base_code  = iv_base_code
        AND   ROWNUM                    = 1;
        --
        IF ln_base_count = 0 THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10217
                            ,iv_token_name1  => cv_tkn_dept_code
                            ,iv_token_value1 => iv_base_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
        -- ========================================
        -- 2-4.�c�Ǝ� �ۊǏꏊ�̎擾
        -- ========================================
        BEGIN
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.�ۊǏꏊ�R�[�h
                    ,msi.attribute7                 AS base_code                    -- 2.���_�R�[�h
                    ,msi.disable_date               AS disable_date                 -- 3.������
                    ,msi.attribute5                 AS subinv_div                   -- 4.�I���Ώ�
            INTO
                     ov_subinv_code                                                 -- 1.�ۊǏꏊ�R�[�h
                    ,ov_base_code                                                   -- 2.���_�R�[�h
                    ,lt_disable_date                                                -- 3.������
                    ,ov_subinv_div                                                  -- 4.�I���Ώ�
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.attribute7                              = lt_belong_base_code
            AND     msi.attribute3                              = lt_salesrep_number
            AND     msi.organization_id                         = in_organization_id
            AND     TRUNC( NVL(msi.disable_date,SYSDATE+1 ) )   > TRUNC( SYSDATE );
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10212
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_belong_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN TOO_MANY_ROWS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10253
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_belong_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10212
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_belong_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_others_error_expt;
        --
        END;
    --
    END IF;
    -- ================================================
    -- 3.�S�ݓXHHT�敪�F���_�P
    -- ================================================
    IF lt_dept_hht_div = cv_dept_hht_single_div THEN
        -- ========================================
        -- 3-1.�c�Ǝ� �ۊǏꏊ�̎擾
        -- ========================================
        BEGIN
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.�ۊǏꏊ�R�[�h
                    ,msi.attribute7                 AS base_code                    -- 2.���_�R�[�h
                    ,msi.disable_date               AS disable_date                 -- 3.������
                    ,msi.attribute5                 AS subinv_div                   -- 4.�I���Ώ�
            INTO
                     ov_subinv_code                                                 -- 1.�ۊǏꏊ�R�[�h
                    ,ov_base_code                                                   -- 2.���_�R�[�h
                    ,lt_disable_date                                                -- 3.������
                    ,ov_subinv_div                                                  -- 4.�I���Ώ�
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.attribute7                              = iv_base_code
            AND     msi.attribute3                              = iv_employee_number
            AND     msi.organization_id                         = in_organization_id
            AND     TRUNC(NVL( msi.disable_date,SYSDATE+1 ) )   > TRUNC(SYSDATE);
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10212
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => iv_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN TOO_MANY_ROWS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10253
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => iv_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10212
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => iv_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_others_error_expt;
        --
        END;
    --
    END IF;
  --
  EXCEPTION
  --
    WHEN sub_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN sub_others_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    --
    WHEN OTHERS THEN
        ov_errmsg  := SQLERRM;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END convert_emp_subinv_code;
/************************************************************************
 * Procedure Name  : CONVERT_CUST_SUBINV_CODE
 * Description     : HHT�a����ۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_cust_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code                    IN         VARCHAR2   -- 4.���_�R�[�h
   ,iv_cust_code                    IN         VARCHAR2   -- 5.�ڋq�R�[�h
   ,id_transaction_date             IN         DATE       -- 6.�`�[���t
   ,in_organization_id              IN         NUMBER     -- 7.�݌ɑg�DID
   ,iv_record_type                  IN         VARCHAR2   -- 8.���R�[�h���
   ,iv_hht_form_flag                IN         VARCHAR2   -- 9.HHT������͉�ʃt���O
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   --10.�ۊǏꏊ�R�[�h
   ,ov_base_code                    OUT NOCOPY VARCHAR2   --11.���_�R�[�h
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   --12.�ۊǏꏊ��敪
   ,ov_business_low_type            OUT NOCOPY VARCHAR2   --13.�Ƒԏ�����
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'convert_cust_subinv_code';     -- �v���O������
    -- *** ���[�J���萔 ***
    cv_flag_y               CONSTANT VARCHAR2(1) := 'Y';     -- �t���OY
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5) := 'XXCOI';                 -- �A�v���P�[�V�����Z�k��
    cv_dummy_code          CONSTANT VARCHAR2(2) := '99';                    -- �_�~�[�R�[�h
    cv_dept_hht_single_div CONSTANT VARCHAR2(1) := '2';                     -- �S�ݓXHHT�敪�F���_�P(2)
    cv_dept_hht_double_div CONSTANT VARCHAR2(1) := '1';                     -- �S�ݓXHHT�敪�F���_��(1)
    cv_vd_div              CONSTANT VARCHAR2(1) := 'V';                     -- �ۊǏꏊ�R�[�h�̌n�F�ړ���F���̋@
    cv_vd_s_div            CONSTANT VARCHAR2(1) := 'S';                     -- �ۊǏꏊ�R�[�h�̌n�F�ڔ���F����VD
    cv_vd_f_div            CONSTANT VARCHAR2(1) := 'F';                     -- �ۊǏꏊ�R�[�h�̌n�F�ڔ���F�t��VD
    cv_biz_low_type_24     CONSTANT VARCHAR2(2) := '24';                    -- �Ƒԏ����ށF�t��(����)VD
    cv_biz_low_type_25     CONSTANT VARCHAR2(2) := '25';                    -- �Ƒԏ����ށF�t��VD
    cv_biz_low_type_27     CONSTANT VARCHAR2(2) := '27';                    -- �Ƒԏ����ށF����VD
    cv_cust_status_mc      CONSTANT VARCHAR2(2) := '20';                    -- �ڋq�X�e�[�^�X�FMC
    cv_cust_status_sp      CONSTANT VARCHAR2(2) := '25';                    -- �ڋq�X�e�[�^�X�FSP����
    cv_cust_status_appl    CONSTANT VARCHAR2(2) := '30';                    -- �ڋq�X�e�[�^�X�F���F��
    cv_cust_status_cust    CONSTANT VARCHAR2(2) := '40';                    -- �ڋq�X�e�[�^�X�F�ڋq
    cv_cust_status_rest    CONSTANT VARCHAR2(2) := '50';                    -- �ڋq�X�e�[�^�X�F�x�~
    cv_cust_status_credit  CONSTANT VARCHAR2(2) := '80';                    -- �ڋq�X�e�[�^�X�F�X����
    cv_record_type_sample  CONSTANT VARCHAR2(2) := '40';                    -- ���R�[�h��ʁF���{
    cv_record_type_inv     CONSTANT VARCHAR2(2) := '90';                    -- ���R�[�h��ʁF�I��
    cv_cust_class_base     CONSTANT VARCHAR2(1) := '1';                     -- �ڋq�敪�F���_
    cv_cust_class_cust     CONSTANT VARCHAR2(2) := '10';                    -- �ڋq�敪�F�ڋq
    cv_cust_class_uesama   CONSTANT VARCHAR2(2) := '12';                    -- �ڋq�敪�F��l
    --
    cv_msg_coi_10204       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10204';     -- �S�ݓXHHT�敪�擾�G���[
    cv_msg_coi_10214       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10214';     -- �Ǌ����_�擾�G���[
    cv_msg_coi_10215       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10215';     -- �Ǌ����_���ݒ�G���[
    cv_msg_coi_10216       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10216';     -- �ڋq�X�e�[�^�X�G���[
    cv_msg_coi_10210       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10210';     -- �Ǘ������_�s��v�G���[
    cv_msg_coi_10219       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10219';     -- �a����ۊǏꏊ�擾�G���[
    cv_msg_coi_10252       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10252';     -- �a����ۊǏꏊ�d���G���[
    cv_msg_coi_10220       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10220';     -- �a����ۊǏꏊ�����G���[
    cv_msg_coi_10206       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10206';     -- �ۊǏꏊ�̎擾�G���[
    cv_msg_coi_10207       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10207';     -- �ۊǏꏊ�̎����G���[
    cv_msg_coi_10218       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10218';     -- �Ǌ����_�s��v�G���[
    --
    cv_msg_coi_10344       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10344';     -- �t��VD���_�ۊǏꏊ�擾�G���[
    cv_msg_coi_10345       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10345';     -- �t��VD���_�ۊǏꏊ�����G���[
    cv_msg_coi_10346       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10346';     -- ����VD���_�ۊǏꏊ�擾�G���[
    cv_msg_coi_10347       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10347';     -- ����VD���_�ۊǏꏊ�����G���[
    --
    cv_tkn_dept_code       CONSTANT VARCHAR2(13) := 'DEPT_CODE';
    cv_tkn_cust_code       CONSTANT VARCHAR2(13) := 'CUST_CODE';
    cv_tkn_sub_inv_code    CONSTANT VARCHAR2(13) := 'SUB_INV_CODE';
    -- *** ���[�J���ϐ� ***
    lt_dept_hht_div         xxcmm_cust_accounts.dept_hht_div%TYPE;                      -- �S�ݓX�pHHT�敪
    lt_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;                    -- �Ǌ����_
    lt_cust_status          hz_parties.duns_number_c%TYPE;                              -- �ڋq�X�e�[�^�X
    lt_customer_class_code  hz_cust_accounts.customer_class_code%TYPE;                  -- �ڋq�敪
    lt_sub_inv_name         mtl_secondary_inventories.secondary_inventory_name%TYPE;    -- �ۊǏꏊ�R�[�h
    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;                -- �ۊǏꏊ������
    ln_base_count           NUMBER := 0;                                                -- �Ǘ������_��v����
    --
    -- *** ���[�J����O ***
    sub_error_expt          EXCEPTION;                                         -- �T�u��`��O�G���[
    sub_others_error_expt   EXCEPTION;                                         -- �T�u��`Oters��O�G���[
  --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
    -- ====================================================
    -- 1.�S�ݓX�pHHT�敪 �擾
    -- ====================================================
    --
    BEGIN
    --
        SELECT NVL(xca.dept_hht_div,cv_dept_hht_single_div)     -- 1.�S�ݓX�pHHT�敪
        INTO   lt_dept_hht_div                                  -- 1.�S�ݓX�pHHT�敪
        FROM   hz_cust_accounts hca
               ,xxcmm_cust_accounts xca
        WHERE  hca.cust_account_id      = xca.customer_id
        AND    hca.account_number       = iv_base_code
        AND    hca.customer_class_code  = cv_cust_class_base;
    --
    EXCEPTION
     --
        WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10204
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_error_expt;
        --
        WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10204
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_others_error_expt;
    --
    END;
    -- ================================================
    -- 2.�ڋq�̊Ǌ����_���擾
    -- ================================================
    BEGIN
    --
        SELECT
                CASE TO_CHAR(id_transaction_date,'YYYYMM') 
                    WHEN TO_CHAR(cd_business_date,'YYYYMM' )
                      THEN NVL(xca.sale_base_code,cv_dummy_code)
                    ELSE NVL(xca.past_sale_base_code,cv_dummy_code)
                    END                    AS base_code                 -- 1.�Ǌ����_�R�[�h
                 ,hp.duns_number_c         AS cust_status               -- 2.�ڋq�X�e�[�^�X
                 ,xca.business_low_type    AS business_low_type         -- 3.�Ƒԏ�����
                 ,hca.customer_class_code  AS customer_class_code       -- 4.�ڋq�敪
        INTO
                 lt_base_code                                           -- 1.�Ǌ����_�R�[�h
                ,lt_cust_status                                         -- 2.�ڋq�X�e�[�^�X
                ,ov_business_low_type                                   -- 3.�Ƒԏ�����
                ,lt_customer_class_code                                 -- 4.�ڋq�敪
        FROM
                 hz_parties hp
                ,hz_cust_accounts hca
                ,xxcmm_cust_accounts xca
        WHERE
                hp.party_id         = hca.party_id
        AND     hca.cust_account_id = xca.customer_id
        AND     hca.account_number  = iv_cust_code
        AND     hca.customer_class_code IN( cv_cust_class_cust , cv_cust_class_uesama );
    --
    EXCEPTION
    --
        WHEN NO_DATA_FOUND THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10214
                            ,iv_token_name1  => cv_tkn_cust_code
                            ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        WHEN OTHERS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10214
                            ,iv_token_name1  => cv_tkn_cust_code
                            ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_others_error_expt;
    --
    END;
    -- ========================================
    -- 3.���_�R�[�h�̖��ݒ��O
    -- ========================================
    IF lt_base_code = cv_dummy_code THEN
    --
        lv_errmsg  := xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_kbn_coi
                  ,iv_name         => cv_msg_coi_10215
                  ,iv_token_name1  => cv_tkn_cust_code
                  ,iv_token_value1 => iv_cust_code
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_error_expt;
    --
    END IF;
    -- ========================================
    -- 4.�ڋq�X�e�[�^�X�`�F�b�N
    -- ========================================
    -- 12:��l�ڋq
    IF lt_customer_class_code = cv_cust_class_uesama THEN
    --
        IF lt_cust_status NOT IN( cv_cust_status_appl   -- 30:���F
                                 ,cv_cust_status_cust ) -- 40:�ڋq
        THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10216
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    --
    ELSE
    --
        IF iv_record_type = cv_record_type_inv THEN         -- 90:�I��
        --
            IF lt_cust_status NOT IN( cv_cust_status_appl      -- 30:���F
                                     ,cv_cust_status_cust      -- 40:�ڋq
                                     ,cv_cust_status_rest      -- 50:�x�~
                                     ,cv_cust_status_credit )  -- 80:�X����
            THEN
            --
                lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                          ,iv_name         => cv_msg_coi_10216
                          ,iv_token_name1  => cv_tkn_cust_code
                          ,iv_token_value1 => iv_cust_code
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            END IF;
        --
        ELSE
        --
            IF ( ( iv_hht_form_flag IS NOT NULL ) AND ( iv_hht_form_flag = cv_flag_y ) ) THEN
                -- HHT������͉�ʂ̏ꍇ
                IF lt_cust_status NOT IN( cv_cust_status_appl      -- 30:���F
                                         ,cv_cust_status_cust      -- 40:�ڋq
                                         ,cv_cust_status_rest      -- 50:�x�~
                                         ,cv_cust_status_credit )  -- 80:�X����
                THEN
                --
                    lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_coi
                              ,iv_name         => cv_msg_coi_10216
                              ,iv_token_name1  => cv_tkn_cust_code
                              ,iv_token_value1 => iv_cust_code
                                  );
                    lv_errbuf := SQLERRM;
                    RAISE sub_error_expt;
                --
                END IF;
            --
            ELSE
                -- HHT_IF�̏ꍇ
                IF lt_cust_status NOT IN( cv_cust_status_appl   -- 30:���F
                                         ,cv_cust_status_cust   -- 40:�ڋq
                                         ,cv_cust_status_rest)  -- 50:�x�~
                                         
                THEN
                --
                    lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_coi
                              ,iv_name         => cv_msg_coi_10216
                              ,iv_token_name1  => cv_tkn_cust_code
                              ,iv_token_value1 => iv_cust_code
                                  );
                    lv_errbuf := SQLERRM;
                    RAISE sub_error_expt;
                --
                END IF;

            END IF;
        --
        END IF;
    --
    END IF;
    -- ========================================
    -- 5.���_���̏ꍇ�́A�Ǘ������_�̈�v�`�F�b�N
    -- ========================================
    IF lt_dept_hht_div = cv_dept_hht_double_div THEN
    --
        SELECT
              COUNT(1) AS COUNT            -- 1.�Ǘ������_�̈�v����
        INTO
              ln_base_count                -- 1.�Ǘ������_�̈�v����
        FROM
              hz_cust_accounts hca
             ,xxcmm_cust_accounts xca
        WHERE
              hca.cust_account_id       = xca.customer_id
        AND   hca.customer_class_code   = cv_cust_class_base
        AND   hca.account_number        = lt_base_code
        AND   xca.management_base_code  = iv_base_code
        AND   ROWNUM = 1;
        --
        IF ln_base_count = 0 THEN
            --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10210
                            ,iv_token_name1  => cv_tkn_dept_code
                            ,iv_token_value1 => iv_base_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    -- ========================================
    -- 6.���_�P�̏ꍇ�́A�Ǌ����_�̈�v�`�F�b�N
    -- ========================================
    ELSE
    --
        IF iv_base_code <> lt_base_code THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10218
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => iv_base_code
                              );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    --
    END IF;
    -- ========================================
    -- 2-5.�a���� �ۊǏꏊ�̎擾
    -- ========================================
    -- -------------------------
    -- 2-5-1.����VD(27)
    -- -------------------------
    IF ov_business_low_type = cv_biz_low_type_27 THEN
    --
        BEGIN
        -- 
            lt_sub_inv_name := cv_vd_div||lt_base_code||cv_vd_s_div;
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.�ۊǏꏊ�R�[�h
                    ,msi.attribute7                 AS base_code                    -- 2.���_�R�[�h
                    ,msi.disable_date               AS disable_date                 -- 3.������
                    ,msi.attribute5                 AS subinv_div                   -- 4.�I���Ώ�
            INTO
                     ov_subinv_code                                                 -- 1.�ۊǏꏊ�R�[�h
                    ,ov_base_code                                                   -- 2.���_�R�[�h
                    ,lt_disable_date                                                -- 3.������
                    ,ov_subinv_div                                                  -- 4.�I���Ώ�
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.secondary_inventory_name    = lt_sub_inv_name
            AND     msi.organization_id             = in_organization_id;
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10346
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_s_div
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10346
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_s_div
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
        --
        END;
        --
        IF lt_disable_date IS NOT NULL AND TRUNC(lt_disable_date) <= TRUNC(SYSDATE) THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10347
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_s_div
                            );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    -- -------------------------
    -- 2-5-2.�t��VD(24,25)
    -- -------------------------
    ELSIF ov_business_low_type IN(cv_biz_low_type_24,cv_biz_low_type_25) THEN
    --
        BEGIN
        --
            lt_sub_inv_name := cv_vd_div||lt_base_code||cv_vd_f_div;
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.�ۊǏꏊ�R�[�h
                    ,msi.attribute7                 AS base_code                    -- 2.���_�R�[�h
                    ,msi.disable_date               AS disable_date                 -- 3.������
                    ,msi.attribute5                 AS subinv_div                   -- 4.�I���Ώ�
            INTO
                     ov_subinv_code                                                 -- 1.�ۊǏꏊ�R�[�h
                    ,ov_base_code                                                   -- 2.���_�R�[�h
                    ,lt_disable_date                                                -- 3.������
                    ,ov_subinv_div                                                  -- 4.�I���Ώ�
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.secondary_inventory_name    = lt_sub_inv_name
            AND     msi.organization_id             = in_organization_id;
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10344
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_f_div
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10344
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_f_div
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
        --
        END;
        --
        IF lt_disable_date IS NOT NULL AND TRUNC(lt_disable_date) <= TRUNC(SYSDATE) THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10345
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_f_div
                            );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    -- -------------------------
    -- 2-5-1.�ȊO
    -- -------------------------
    ELSE
    --
        BEGIN
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.�ۊǏꏊ�R�[�h
                    ,msi.attribute7                 AS base_code                    -- 2.���_�R�[�h
                    ,msi.disable_date               AS disable_date                 -- 3.������
                    ,msi.attribute5                 AS subinv_div                   -- 4.�I���Ώ�
            INTO
                     ov_subinv_code                                                 -- 1.�ۊǏꏊ�R�[�h
                    ,ov_base_code                                                   -- 2.���_�R�[�h
                    ,lt_disable_date                                                -- 3.������
                    ,ov_subinv_div                                                  -- 4.�I���Ώ�
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.attribute7                              = lt_base_code
            AND     msi.attribute4                              = iv_cust_code
            AND     msi.organization_id                         = in_organization_id
            AND     TRUNC( NVL(msi.disable_date,SYSDATE+1) )    > TRUNC(SYSDATE);
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10219
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_base_code
                                ,iv_token_name2  => cv_tkn_cust_code
                                ,iv_token_value2 => iv_cust_code
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN TOO_MANY_ROWS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10252
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_base_code
                                ,iv_token_name2  => cv_tkn_cust_code
                                ,iv_token_value2 => iv_cust_code
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10219
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_base_code
                                ,iv_token_name2  => cv_tkn_cust_code
                                ,iv_token_value2 => iv_cust_code
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
        --
        END;
        --
    END IF;
  --
  EXCEPTION
  --
    WHEN sub_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN sub_others_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    --
    WHEN OTHERS THEN
        ov_errmsg  := SQLERRM;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END convert_cust_subinv_code;
/************************************************************************
 * Procedure Name  : CONVERT_BASE_SUBINV_CODE
 * Description     : HHT���C���q�ɕۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_base_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_dept_code                    IN         VARCHAR2   -- 4.���_�R�[�h
   ,in_organization_id              IN         NUMBER     -- 5.�݌ɑg�DID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 6.�ۊǏꏊ�R�[�h
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 7.���_�R�[�h
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 8.�ۊǏꏊ�ϊ��敪
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'convert_base_subinv_code';     -- �v���O������
    -- *** ���[�J���萔 ***
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';                        -- �A�v���P�[�V�����Z�k��
    cv_msg_coi_10221       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10221';             -- �ۊǏꏊ�擾�G���[
    cv_msg_coi_10251       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10251';             -- �ۊǏꏊ�d���G���[
    --
    cv_tkn_dept_code       CONSTANT VARCHAR2(13) := 'DEPT_CODE';
    --
    cv_main_warehouse_flag CONSTANT VARCHAR2(1) := 'Y';                             -- ���C���q�Ƀt���O
    -- *** ���[�J���ϐ� ***
    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;            -- �ۊǏꏊ������
    -- *** ���[�J����O ***
  --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    SELECT 
             msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.�ۊǏꏊ�R�[�h
            ,msi.attribute7                 AS base_code                    -- 2.���_�R�[�h
            ,msi.disable_date               AS disable_date                 -- 3.������
            ,msi.attribute5                 AS subinv_div                   -- 4.�I���Ώ�
    INTO
             ov_subinv_code                                                 -- 1.�ۊǏꏊ�R�[�h
            ,ov_base_code                                                   -- 2.���_�R�[�h
            ,lt_disable_date                                                -- 3.������
            ,ov_subinv_div                                                  -- 4.�I���Ώ�    
    FROM    mtl_secondary_inventories msi 
    WHERE   msi.attribute7                              = iv_dept_code
    AND     msi.attribute6                              = cv_main_warehouse_flag
    AND     msi.organization_id                         = in_organization_id
    AND     TRUNC( NVL(msi.disable_date , SYSDATE+1 ) ) > TRUNC(SYSDATE);
    --
  EXCEPTION
    --
    WHEN NO_DATA_FOUND THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10221
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_dept_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN TOO_MANY_ROWS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10251
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_dept_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10221
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_dept_code
                      );
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END convert_base_subinv_code;
/************************************************************************
 * Procedure Name  : CHECK_CUST_STATUS
 * Description     : HHT�ڋq�X�e�[�^�X�`�F�b�N
 ************************************************************************/
  PROCEDURE check_cust_status(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_cust_code                    IN         VARCHAR2   -- 4.�ڋq�R�[�h
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'check_cust_status';   -- �v���O������
    -- *** ���[�J���萔 ***
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';                -- �A�v���P�[�V�����Z�k��
    cv_msg_coi_10214       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10223';     -- MSG�F�ڋq�ð���擾�G���[
    cv_msg_coi_10303       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10303';     -- MSG�F�ڋq�X�e�[�^�X�G���[
    cv_tkn_cust_code       CONSTANT VARCHAR2(13) := 'CUST_CODE';            -- TKN�F�ڋq�R�[�h
    cv_cust_status_mc      CONSTANT VARCHAR2(2)  := '20';                   -- �ڋq�X�e�[�^�X�FMC
    cv_cust_status_sp      CONSTANT VARCHAR2(2)  := '25';                   -- �ڋq�X�e�[�^�X�FSP����
    cv_cust_status_appl    CONSTANT VARCHAR2(2)  := '30';                   -- �ڋq�X�e�[�^�X�F���F��
    cv_cust_status_cust    CONSTANT VARCHAR2(2)  := '40';                   -- �ڋq�X�e�[�^�X�F�ڋq
    cv_cust_status_rest    CONSTANT VARCHAR2(2)  := '50';                   -- �ڋq�X�e�[�^�X�F�x�~
    cv_cust_class_uesama   CONSTANT VARCHAR2(2)  := '12';                   -- �ڋq�敪�F��l
    -- *** ���[�J���ϐ� ***
    lt_cust_status         hz_parties.duns_number_c%TYPE;                   -- �ڋq�X�e�[�^�X
    lt_customer_class_code hz_cust_accounts.customer_class_code%TYPE;       -- �ڋq�敪
    -- *** ���[�J����O ***
    sub_error_expt         EXCEPTION;                                       -- �T�u��`��O�G���[
  --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ================================================
    -- 1.�ڋq�X�e�[�^�X���擾
    -- ================================================
    BEGIN
    --
        SELECT
                 hp.duns_number_c         AS duns_number_c             -- 1.�ڋq�X�e�[�^�X
                ,hca.customer_class_code  AS customer_class_code       -- 2.�ڋq�敪
        INTO
                 lt_cust_status                                        -- 1.�ڋq�X�e�[�^�X
                ,lt_customer_class_code                                -- 2.�ڋq�敪
        FROM
                 hz_parties hp
                ,hz_cust_accounts hca
        WHERE
                hp.party_id         = hca.party_id
        AND     hca.account_number  = iv_cust_code;
    --
    EXCEPTION
    --
        WHEN OTHERS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10214
                            ,iv_token_name1  => cv_tkn_cust_code
                            ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
    --
    END;
    -- ========================================
    -- 2.�ڋq�X�e�[�^�X�`�F�b�N
    -- ========================================
    -- 12:��l�ڋq
    IF lt_customer_class_code = cv_cust_class_uesama THEN
    --
        IF lt_cust_status NOT IN( cv_cust_status_appl   -- 30:���F
                                 ,cv_cust_status_cust ) -- 40:�ڋq
        THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10303
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    --
    ELSE
    --
        IF lt_cust_status NOT IN( cv_cust_status_mc     -- 20:MC
                                 ,cv_cust_status_sp     -- 25:SP
                                 ,cv_cust_status_appl   -- 30:���F
                                 ,cv_cust_status_cust   -- 40:�ڋq
                                 ,cv_cust_status_rest ) -- 50:�x�~
        THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10303
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
  --
  END IF;
  --
  EXCEPTION
  --
    WHEN sub_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN OTHERS THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END check_cust_status;
/************************************************************************
 * Procedure Name  : CONVERT_SUBINV_CODE
 * Description     : HHT�ۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_record_type                  IN         VARCHAR2   -- 4.���R�[�h���
   ,iv_invoice_type                 IN         VARCHAR2   -- 5.�`�[�敪
   ,iv_department_flag              IN         VARCHAR2   -- 6.�S�ݓX�t���O
   ,iv_base_code                    IN         VARCHAR2   -- 7.���_�R�[�h
   ,iv_outside_code                 IN         VARCHAR2   -- 8.�o�ɑ��R�[�h
   ,iv_inside_code                  IN         VARCHAR2   -- 9.���ɑ��R�[�h
   ,id_transaction_date             IN         DATE       -- 10.�����
   ,in_organization_id              IN         NUMBER     -- 11.�݌ɑg�DID
   ,iv_hht_form_flag                IN         VARCHAR2   -- 12.HHT������͉�ʃt���O
   ,ov_outside_subinv_code          OUT NOCOPY VARCHAR2   -- 13.�o�ɑ��ۊǏꏊ�R�[�h
   ,ov_inside_subinv_code           OUT NOCOPY VARCHAR2   -- 14.���ɑ��ۊǏꏊ�R�[�h
   ,ov_outside_base_code            OUT NOCOPY VARCHAR2   -- 15.�o�ɑ����_�R�[�h
   ,ov_inside_base_code             OUT NOCOPY VARCHAR2   -- 16.���ɑ����_�R�[�h
   ,ov_outside_subinv_code_conv     OUT NOCOPY VARCHAR2   -- 17.�o�ɑ��ۊǏꏊ�ϊ��敪
   ,ov_inside_subinv_code_conv      OUT NOCOPY VARCHAR2   -- 18.���ɑ��ۊǏꏊ�ϊ��敪
   ,ov_outside_business_low_type    OUT NOCOPY VARCHAR2   -- 19.�o�ɑ��Ƒԏ�����
   ,ov_inside_business_low_type     OUT NOCOPY VARCHAR2   -- 20.���ɑ��Ƒԏ�����
   ,ov_outside_cust_code            OUT NOCOPY VARCHAR2   -- 21.�o�ɑ��ڋq�R�[�h
   ,ov_inside_cust_code             OUT NOCOPY VARCHAR2   -- 22.���ɑ��ڋq�R�[�h
   ,ov_hht_program_div              OUT NOCOPY VARCHAR2   -- 23.���o�ɃW���[�i�������敪
   ,ov_item_convert_div             OUT NOCOPY VARCHAR2   -- 24.���i�U�֋敪
   ,ov_stock_uncheck_list_div       OUT NOCOPY VARCHAR2   -- 25.���ɖ��m�F���X�g�Ώۋ敪
   ,ov_stock_balance_list_div       OUT NOCOPY VARCHAR2   -- 26.���ɍ��يm�F���X�g�Ώۋ敪
   ,ov_consume_vd_flag              OUT NOCOPY VARCHAR2   -- 27.����VD��[�Ώۃt���O
   ,ov_outside_subinv_div           OUT NOCOPY VARCHAR2   -- 28.�o�ɑ��I���Ώ�
   ,ov_inside_subinv_div            OUT NOCOPY VARCHAR2   -- 29.���ɑ��I���Ώ�
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'convert_subinv_code';   -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';              -- �A�v���P�[�V�����Z�k��
    cv_msg_coi_10225       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10225';   -- �g�ݍ��킹�G���[���b�Z�[�W
    --
    cv_tkn_record_type     CONSTANT VARCHAR2(13) := 'RECORD_TYPE';
    cv_tkn_invoice_type    CONSTANT VARCHAR2(13) := 'INVOICE_TYPE';
    cv_tkn_department_flag CONSTANT VARCHAR2(13) := 'DEPT_FLAG';
    --
    cv_dummy_code          CONSTANT VARCHAR2(2)  := '99';
    cv_cust_class_base     CONSTANT VARCHAR2(1)  := '1';                     -- �ڋq�敪�F���_
    cv_warehouse_div       CONSTANT VARCHAR2(1)  := 'A';                     -- �q��
    cv_sales_div           CONSTANT VARCHAR2(1)  := 'B';                     -- �c�Ǝ�
    cv_cust_div            CONSTANT VARCHAR2(1)  := 'C';                     -- �a����
    cv_inside_main_div     CONSTANT VARCHAR2(1)  := 'D';                     -- ���C���q��
    cv_outside_main_div    CONSTANT VARCHAR2(1)  := 'E';                     -- �a���惁�C���q��
    cv_customer_div        CONSTANT VARCHAR2(1)  := 'F';                     -- �ڋq
    -- *** ���[�J���ϐ� ***
    lt_cust_base_code      xxcmm_cust_accounts.sale_base_code%TYPE;          -- �a���拒�_�R�[�h
    -- *** ���[�J����O ***
    sub_error_expt          EXCEPTION;                                       -- �l�擾�G���[
    sub_prog_error_expt     EXCEPTION;                                       -- �T�u�E�v���O�����G���[
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ========================
    -- 1.�R�[�h�ϊ���`��� �擾
    -- ========================
    BEGIN
    --
        SELECT   
                 xhecv.outside_subinv_code_conv_div AS  outside_subinv_code_conv_div      -- 1.�o�ɑ��ۊǏꏊ�ϊ��敪
                ,xhecv.inside_subinv_code_conv_div  AS  inside_subinv_code_conv_div       -- 2.���ɑ��ۊǏꏊ�ϊ��敪
                ,xhecv.program_div                  AS  program_div                       -- 3.���o�ɃW���[�i�������敪
                ,xhecv.consume_vd_flag              AS  consume_vd_flag                   -- 4.����VD��[�Ώۃt���O
                ,xhecv.stock_uncheck_list_div       AS  stock_uncheck_list_div            -- 5.���ɖ��m�F���X�g�Ώۋ敪
                ,xhecv.stock_balance_list_div       AS  stock_balance_list_div            -- 6.���ɍ��يm�F���X�g�Ώۋ�
                ,xhecv.item_convert_div             AS  item_convert_div                  -- 7.���i�U�֋敪
        INTO     
                 ov_outside_subinv_code_conv                                              -- 1.�o�ɑ��ۊǏꏊ�ϊ��敪
                ,ov_inside_subinv_code_conv                                               -- 2.���ɑ��ۊǏꏊ�ϊ��敪
                ,ov_hht_program_div                                                       -- 3.���o�ɃW���[�i�������敪
                ,ov_consume_vd_flag                                                       -- 4.����VD��[�Ώۃt���O
                ,ov_stock_uncheck_list_div                                                -- 5.���ɖ��m�F���X�g�Ώۋ敪
                ,ov_stock_balance_list_div                                                -- 6.���ɍ��يm�F���X�g�Ώۋ敪
                ,ov_item_convert_div                                                      -- 7.���i�U�֋敪
        FROM    xxcoi_hht_ebs_convert_v xhecv
        WHERE   xhecv.record_type       = iv_record_type
        AND     xhecv.invoice_type      = NVL(iv_invoice_type,cv_dummy_code)
        AND     xhecv.department_flag   = NVL(iv_department_flag,cv_dummy_code)
        AND     TRUNC(cd_business_date) 
                    BETWEEN TRUNC( xhecv.start_date_active ) 
                        AND TRUNC( NVL( xhecv.end_date_active,cd_business_date ) );
    --
    EXCEPTION
    --
        WHEN NO_DATA_FOUND THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10225
                            ,iv_token_name1  => cv_tkn_record_type
                            ,iv_token_value1 => iv_record_type
                            ,iv_token_name2  => cv_tkn_invoice_type
                            ,iv_token_value2 => iv_invoice_type
                            ,iv_token_name3  => cv_tkn_department_flag
                            ,iv_token_value3 => iv_department_flag
                          );
            lv_retcode := cv_status_warn;
            lv_errbuf  := SQLERRM;
            RAISE sub_error_expt;
        --
        WHEN TOO_MANY_ROWS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10225
                            ,iv_token_name1  => cv_tkn_record_type
                            ,iv_token_value1 => iv_record_type
                            ,iv_token_name2  => cv_tkn_invoice_type
                            ,iv_token_value2 => iv_invoice_type
                            ,iv_token_name3  => cv_tkn_department_flag
                            ,iv_token_value3 => iv_department_flag
                          );
            lv_retcode := cv_status_warn;
            lv_errbuf  := SQLERRM;
            RAISE sub_error_expt;
        --
        WHEN OTHERS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10225
                            ,iv_token_name1  => cv_tkn_record_type
                            ,iv_token_value1 => iv_record_type
                            ,iv_token_name2  => cv_tkn_invoice_type
                            ,iv_token_value2 => iv_invoice_type
                            ,iv_token_name3  => cv_tkn_department_flag
                            ,iv_token_value3 => iv_department_flag
                          );
            lv_retcode := cv_status_error;
            lv_errbuf  := SQLERRM;
            RAISE sub_error_expt;
    --
    END;
    -- ========================
    -- 2.�q�ɕۊǏ�ꏊ �擾(A)
    -- ========================
    -- ----------------------------------------------------
    -- 2-1.�o�ɑ� �q�ɕۊǏ�ꏊ �擾
    -- ----------------------------------------------------
    IF ov_outside_subinv_code_conv = cv_warehouse_div THEN
    --
        convert_whouse_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.�G���[���b�Z�[�W
           ,ov_retcode          => lv_retcode               -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           => lv_errmsg                -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_base_code        => iv_base_code             -- 4.���_�R�[�h
           ,iv_warehouse_code   => iv_outside_code          -- 5.�q�ɃR�[�h
           ,in_organization_id  => in_organization_id       -- 6.�݌ɑg�DID
           ,ov_subinv_code      => ov_outside_subinv_code   -- 7.�ۊǏꏊ�R�[�h
           ,ov_base_code        => ov_outside_base_code     -- 8.���_�R�[�h
           ,ov_subinv_div       => ov_outside_subinv_div    -- 9.�I���Ώ�
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ----------------------------------------------------
    -- 2-2.���ɑ� �q�ɕۊǏ�ꏊ �擾
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_warehouse_div THEN
    --
        convert_whouse_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.�G���[���b�Z�[�W
           ,ov_retcode          => lv_retcode               -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           => lv_errmsg                -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_base_code        => iv_base_code             -- 4.���_�R�[�h
           ,iv_warehouse_code   => iv_inside_code           -- 5.�q�ɃR�[�h
           ,in_organization_id  => in_organization_id       -- 6.�݌ɑg�DID
           ,ov_subinv_code      => ov_inside_subinv_code    -- 7.�ۊǏꏊ�R�[�h
           ,ov_base_code        => ov_inside_base_code      -- 8.���_�R�[�h
           ,ov_subinv_div       => ov_inside_subinv_div     -- 9.�I���Ώ�
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ==========================
    -- 3.�c�ƎҕۊǏ�ꏊ �擾(B)
    -- ==========================
    -- ----------------------------------------------------
    -- 3-1.�o�ɑ� �c�ƎԕۊǏ�ꏊ �擾
    -- ----------------------------------------------------
    IF ov_outside_subinv_code_conv = cv_sales_div THEN
        --
        convert_emp_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.�G���[���b�Z�[�W
           ,ov_retcode          => lv_retcode               -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           => lv_errmsg                -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_base_code        => iv_base_code             -- 4.���_�R�[�h
           ,iv_employee_number  => iv_outside_code          -- 5.�]�ƈ��R�[�h
           ,in_organization_id  => in_organization_id       -- 6.�݌ɑg�DID
           ,id_transaction_date => id_transaction_date      -- 7.�`�[���t
           ,ov_subinv_code      => ov_outside_subinv_code   -- 8.�ۊǏꏊ�R�[�h
           ,ov_base_code        => ov_outside_base_code     -- 9.���_�R�[�h
           ,ov_subinv_div       => ov_outside_subinv_div    --10.�I���Ώ�
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    --
    -- ----------------------------------------------------
    -- 3-2.���ɑ� �c�ƎԕۊǏ�ꏊ �擾
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_sales_div THEN
        --
        convert_emp_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.�G���[���b�Z�[�W
           ,ov_retcode          => lv_retcode               -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           => lv_errmsg                -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_base_code        => iv_base_code             -- 4.���_�R�[�h
           ,iv_employee_number  => iv_inside_code           -- 5.�]�ƈ��R�[�h
           ,in_organization_id  => in_organization_id       -- 6.�݌ɑg�DID
           ,id_transaction_date => id_transaction_date      -- 7.�`�[���t
           ,ov_subinv_code      => ov_inside_subinv_code    -- 8.�ۊǏꏊ�R�[�h
           ,ov_base_code        => ov_inside_base_code      -- 9.���_�R�[�h
           ,ov_subinv_div       => ov_inside_subinv_div     --10.�I���Ώ�
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ==========================
    -- 4.�a����ۊǏ�ꏊ �擾(C)
    -- ==========================
    -- ----------------------------------------------------
    -- 4-1.�o�ɑ� �a����ۊǏ�ꏊ �擾
    -- ----------------------------------------------------
    IF ov_outside_subinv_code_conv = cv_cust_div THEN
        --
        convert_cust_subinv_code(
            ov_errbuf            => lv_errbuf                       -- 1.�G���[���b�Z�[�W
           ,ov_retcode           => lv_retcode                      -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg            => lv_errmsg                       -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_base_code         => iv_base_code                    -- 4.���_�R�[�h
           ,iv_cust_code         => iv_outside_code                 -- 5.�ڋq�R�[�h
           ,id_transaction_date  => id_transaction_date             -- 6.�`�[���t
           ,in_organization_id   => in_organization_id              -- 7.�݌ɑg�DID
           ,iv_record_type       => iv_record_type                  -- 8.���R�[�h���
           ,iv_hht_form_flag     => iv_hht_form_flag                -- 9.HHT������͉�ʃt���O
           ,ov_subinv_code       => ov_outside_subinv_code          --10.�ۊǏꏊ�R�[�h
           ,ov_base_code         => ov_outside_base_code            --11.���_�R�[�h
           ,ov_subinv_div        => ov_outside_subinv_div           --12.�I���Ώ�
           ,ov_business_low_type => ov_outside_business_low_type    --13.�Ƒԏ�����
          );
        --
        -- ���ɑ��ڋq�R�[�h���Z�b�g
        ov_outside_cust_code := iv_outside_code;
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    --
    -- ----------------------------------------------------
    -- 4-2.���ɑ� �a����ۊǏ�ꏊ �擾
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_cust_div THEN
        --
        convert_cust_subinv_code(
            ov_errbuf            => lv_errbuf                       -- 1.�G���[���b�Z�[�W
           ,ov_retcode           => lv_retcode                      -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg            => lv_errmsg                       -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_base_code         => iv_base_code                    -- 4.���_�R�[�h
           ,iv_cust_code         => iv_inside_code                  -- 5.�ڋq�R�[�h
           ,id_transaction_date  => id_transaction_date             -- 6.�`�[���t
           ,in_organization_id   => in_organization_id              -- 7.�݌ɑg�DID
           ,iv_record_type       => iv_record_type                  -- 8.���R�[�h���
           ,iv_hht_form_flag     => iv_hht_form_flag                -- 9.HHT������͉�ʃt���O
           ,ov_subinv_code       => ov_inside_subinv_code           --10.�ۊǏꏊ�R�[�h
           ,ov_base_code         => ov_inside_base_code             --11.���_�R�[�h
           ,ov_subinv_div        => ov_inside_subinv_div            --12.�I���Ώ�
           ,ov_business_low_type => ov_inside_business_low_type     --13.�Ƒԏ�����
          );
        -- �a����Ǌ����_���Z�b�g
        lt_cust_base_code := ov_inside_base_code;
        -- ���ɑ��ڋq�R�[�h���Z�b�g
        ov_inside_cust_code := iv_inside_code;
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ==================================
    -- 5.���_���C���q�ɕۊǏ�ꏊ �擾(D)
    -- ==================================
    -- ----------------------------------------------------
    -- 5-1.���ɑ� ���C���q�ɕۊǏ�ꏊ �擾
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_inside_main_div THEN
        --
        convert_base_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.�G���[���b�Z�[�W
           ,ov_retcode          => lv_retcode               -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           => lv_errmsg                -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_dept_code        => iv_inside_code           -- 4.���_�R�[�h
           ,in_organization_id  => in_organization_id       -- 5.�݌ɑg�DID
           ,ov_subinv_code      => ov_inside_subinv_code    -- 6.�ۊǏꏊ�R�[�h
           ,ov_base_code        => ov_inside_base_code      -- 7.���_�R�[�h
           ,ov_subinv_div       => ov_inside_subinv_div     -- 8.�I���Ώ�
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ==================================
    -- 6.�a���惁�C���q�ɕۊǏ�ꏊ �擾(E)
    -- ==================================
    -- ----------------------------------------------------
    -- 6-1.�o�ɑ� ���C���q�ɕۊǏ�ꏊ �擾
    -- ----------------------------------------------------
    IF ov_outside_subinv_code_conv = cv_outside_main_div THEN
        --
        convert_base_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.�G���[���b�Z�[�W
           ,ov_retcode          => lv_retcode               -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           => lv_errmsg                -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_dept_code        => lt_cust_base_code        -- 4.�Ǌ����_�R�[�h
           ,in_organization_id  => in_organization_id       -- 5.�݌ɑg�DID
           ,ov_subinv_code      => ov_outside_subinv_code   -- 6.�ۊǏꏊ�R�[�h
           ,ov_base_code        => ov_outside_base_code     -- 7.���_�R�[�h
           ,ov_subinv_div       => ov_outside_subinv_div    -- 8.�I���Ώ�
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    --
    -- ==================================
    -- 7.�ڋq�X�e�[�^�X�`�F�b�N(F)
    -- ==================================
    -- ----------------------------------------------------
    -- 7-1.���ɑ� �ڋq�X�e�[�^�X�`�F�b�N
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_customer_div THEN
        --
        check_cust_status(
            ov_errbuf           => lv_errbuf                -- 1.�G���[���b�Z�[�W
           ,ov_retcode          => lv_retcode               -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           => lv_errmsg                -- 3.���[�U�[�E�G���[���b�Z�[�W
           ,iv_cust_code        => iv_inside_code           -- 4.�ڋq�R�[�h
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;    
    --
    END IF;
    --
--
  EXCEPTION
    WHEN sub_error_expt THEN              -- *** �l�擾�G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode;
--
    WHEN sub_prog_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode;
--
  END convert_subinv_code;
--
--###########################   END   ##############################
--
/************************************************************************
 * Function Name   : GET_DISPOSITION_ID
 * Description     : ����Ȗڕʖ�������쐬����ۂɕK�v�ƂȂ�
 *                   ����Ȗڕʖ�ID���擾����B�L�������肠��B
 ************************************************************************/
  FUNCTION get_disposition_id(
    iv_inv_account_kbn IN VARCHAR2   -- 1.���o�Ɋ���敪
   ,iv_dept_code       IN VARCHAR2   -- 2.����R�[�h
   ,in_organization_id IN NUMBER     -- 3.�݌ɑg�DID
  ) RETURN NUMBER                    -- ����Ȗڕʖ�ID
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_disposition_id'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ld_date            DATE;                                         -- �Ɩ����t
    lt_disposition_id  mtl_generic_dispositions.disposition_id%TYPE; -- ����Ȗڕʖ�ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t�擾
    ld_date := xxccp_common_pkg2.get_process_date;
--
    -- ====================================================
    -- ����Ȗڕʖ�ID�擾
    -- ====================================================
    SELECT mgd.disposition_id AS disposition_id                                    -- ����Ȗڕʖ�ID
    INTO   lt_disposition_id
    FROM   mtl_generic_dispositions mgd                                            -- ����Ȗڕʖ��e�[�u��
    WHERE  mgd.segment1        = iv_dept_code                                      -- ����R�[�h
    AND    mgd.segment2        = iv_inv_account_kbn                                -- ���o�Ɋ���敪
    AND    mgd.organization_id = in_organization_id                                -- �݌ɑg�DID
    AND    ld_date BETWEEN mgd.effective_date AND NVL( mgd.disable_date, ld_date ) -- �L��������������
    ;
--
    -- �߂�l�Ɋ���Ȗڕʖ�ID��ݒ肵�܂�
    RETURN lt_disposition_id;
--
  EXCEPTION
    -- �擾�Ɏ��s�����ꍇ�ANULL��߂��܂�
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_disposition_id;
--
/************************************************************************
 * Procedure Name  : ADD_HHT_ERR_LIST_DATA
 * Description     : HHT�f�[�^(���o�ɁE�I��)�捞�̍ۂɃG���[�ƂȂ���
 *                   ���R�[�h�����ƂɁAHHT�G���[���X�g���[�ɕK�v��
 *                   �f�[�^��HHT�G���[���X�g���[���[�N�e�[�u���ɒǉ�����B
 ************************************************************************/
  PROCEDURE add_hht_err_list_data(
    ov_errbuf                 OUT VARCHAR2   -- 1.�G���[�E���b�Z�[�W
   ,ov_retcode                OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg                 OUT VARCHAR2   -- 3.���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_base_code              IN  VARCHAR2   -- 4.���_�R�[�h
   ,iv_origin_shipment        IN  VARCHAR2   -- 5.�o�ɑ��R�[�h
   ,iv_data_name              IN  VARCHAR2   -- 6.�f�[�^����
   ,id_transaction_date       IN  DATE       -- 7.�����
   ,iv_entry_number           IN  VARCHAR2   -- 8.�`�[NO
   ,iv_party_num              IN  VARCHAR2   -- 9.���ɑ��R�[�h
   ,iv_performance_by_code    IN  VARCHAR2   -- 10.�c�ƈ��R�[�h
   ,iv_item_code              IN  VARCHAR2   -- 11.�i�ڃR�[�h
   ,iv_error_message          IN  VARCHAR2   -- 12.�G���[���e
  ) 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'add_hht_err_list_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_customer_class_code1 CONSTANT VARCHAR2(1)   := '1';  -- �ڋq�敪 1:���_
    cv_customer_class_code2 CONSTANT VARCHAR2(2)   := '10'; -- �ڋq�敪 10:�ڋq
--
    -- *** ���[�J���ϐ� ***
    lt_party_name1          hz_parties.party_name%TYPE;     -- �������� ���_����
    lt_party_name2          hz_parties.party_name%TYPE;     -- �������� �ڋq��
    lt_account_number       VARCHAR2(9);                    -- �ڋq�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �p�����[�^.���_�R�[�h���ݒ肳��Ă���ꍇ
    IF ( iv_base_code IS NOT NULL ) THEN
--
      BEGIN
        SELECT hp.party_name AS party_name                       -- ��������
        INTO   lt_party_name1                                    -- ���_����
        FROM   hz_parties hp                                     -- �p�[�e�B�[�}�X�^
              ,hz_cust_accounts hca                              -- �ڋq�A�J�E���g
        WHERE  hp.party_id             = hca.party_id            -- �p�[�e�B�[ID
        AND    hca.customer_class_code = cv_customer_class_code1 -- �ڋq�敪
        AND    hca.account_number      = iv_base_code            -- �ڋq�R�[�h
        ;
      -- ��O�������͋��_���̂�NULL��ݒ�
      EXCEPTION
        WHEN OTHERS THEN
          lt_party_name1 := NULL;
      END;
--
    END IF;
--
    -- �p�����[�^.���ɑ��R�[�h�̌�����9���̏ꍇ�A�ڋq�R�[�h�ɐݒ�
    IF ( LENGTHB( iv_party_num ) = 9 ) THEN
       lt_account_number := iv_party_num;
    -- �p�����[�^.�o�ɑ��R�[�h�̌�����9���̏ꍇ�A�ڋq�R�[�h�ɐݒ�
    ELSIF ( LENGTHB( iv_origin_shipment ) = 9 ) THEN
       lt_account_number := iv_origin_shipment;
    -- ��L�ȊO�̏ꍇ�A�ڋq�R�[�h��NULL��ݒ�
    ELSE 
       lt_account_number := NULL;
    END IF;
--
    -- �ڋq�R�[�h���ݒ肳��Ă���ꍇ
    IF ( lt_account_number IS NOT NULL ) THEN
--
      BEGIN
        SELECT hp.party_name AS party_name                       -- ��������
        INTO   lt_party_name2                                    -- �ڋq��
        FROM   hz_parties hp                                     -- �p�[�e�B�[�}�X�^
              ,hz_cust_accounts hca                              -- �ڋq�A�J�E���g
        WHERE  hp.party_id             = hca.party_id            -- �p�[�e�B�[ID
        AND    hca.customer_class_code = cv_customer_class_code2 -- �ڋq�敪
        AND    hca.account_number      = lt_account_number       -- �ڋq�R�[�h
        ;
      -- ��O�������͌ڋq����NULL��ݒ�
      EXCEPTION
        WHEN OTHERS THEN
          lt_party_name2 := NULL;
      END;
--
    END IF;
--
    -- HHT�G���[���X�g���[���[�N�e�[�u���ɓo�^
    INSERT INTO xxcos_rep_hht_err_list(
       record_id                                  -- RECORD_ID
      ,base_code                                  -- ���_�R�[�h
      ,base_name                                  -- ���_����
      ,origin_shipment                            -- �o�ɑ��R�[�h
      ,data_name                                  -- �f�[�^����
      ,order_no_hht                               -- ��NO�iHHT�j
      ,invoice_invent_date                        -- �`�[/�I����
      ,entry_number                               -- �`�[NO
      ,line_no                                    -- �sNO
      ,order_no_ebs                               -- ��NO�iEBS�j
      ,party_num                                  -- �ڋq�R�[�h
      ,customer_name                              -- �ڋq��
      ,payment_dlv_date                           -- ����/�[�i��
      ,payment_class_name                         -- �����敪����
      ,performance_by_code                        -- ���ю҃R�[�h
      ,item_code                                  -- �i�ڃR�[�h
      ,error_message                              -- �G���[���e
      ,report_group_id                            -- ���[�p�O���[�vID
      ,created_by                                 -- �쐬��
      ,creation_date                              -- �쐬��
      ,last_updated_by                            -- �ŏI�X�V��
      ,last_update_date                           -- �ŏI�X�V��
      ,last_update_login                          -- �ŏI�X�V۸޲�
      ,request_id                                 -- �v��ID
      ,program_application_id                     -- �ݶ��ĥ��۸��ѥ���ع����ID
      ,program_id                                 -- �ݶ��ĥ��۸���ID
      ,program_update_date                        -- ��۸��эX�V��
    )
    VALUES(
       xxcos_rep_hht_err_list_s01.nextval         -- RECORD_ID
      ,SUBSTRB( iv_base_code, 1, 4 )              -- ���_�R�[�h
      ,SUBSTRB( lt_party_name1, 1, 30 )           -- ���_����
      ,SUBSTRB( iv_origin_shipment, 1, 9 )        -- �o�ɑ��R�[�h
      ,SUBSTRB( iv_data_name, 1, 20 )             -- �f�[�^����
      ,NULL                                       -- ��No�iHHT�j
      ,id_transaction_date                        -- �`�[/�I����
      ,SUBSTRB( iv_entry_number, 1, 9 )           -- �`�[NO
      ,NULL                                       -- �sNO
      ,NULL                                       -- ��NO�iEBS�j
      ,SUBSTRB( iv_party_num, 1, 9 )              -- �ڋq�R�[�h
      ,SUBSTRB( lt_party_name2, 1, 40 )           -- �ڋq��
      ,NULL                                       -- ����/�[�i��
      ,NULL                                       -- �����敪����
      ,SUBSTRB( iv_performance_by_code, 1, 5 )    -- ���ю҃R�[�h
      ,SUBSTRB( iv_item_code, 1, 7 )              -- �i�ڃR�[�h
      ,SUBSTRB( iv_error_message, 1, 60 )         -- �G���[���e
      ,NULL                                       -- ���[�p�O���[�vID
      ,cn_created_by                              -- �쐬��
      ,cd_creation_date                           -- �쐬��
      ,cn_last_updated_by                         -- �ŏI�X�V��
      ,cd_last_update_date                        -- �ŏI�X�V��
      ,cn_last_update_login                       -- �ŏI�X�V۸޲�
      ,cn_request_id                              -- �v��ID
      ,cn_program_application_id                  -- �ݶ��ĥ��۸��ѥ���ع����ID
      ,cn_program_id                              -- �ݶ��ĥ��۸���ID
      ,cd_program_update_date                     -- ��۸��эX�V��
     ) ;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END add_hht_err_list_data;
--
/************************************************************************
 * Function Name   : GET_DISPOSITION_ID_2
 * Description     : ����Ȗڕʖ�������쐬����ۂɕK�v�ƂȂ�
 *                   ����Ȗڕʖ�ID���擾���܂��B�L��������Ȃ��B
 ************************************************************************/
  FUNCTION get_disposition_id_2(
    iv_inv_account_kbn IN VARCHAR2   -- 1.���o�Ɋ���敪
   ,iv_dept_code       IN VARCHAR2   -- 2.����R�[�h
   ,in_organization_id IN NUMBER     -- 3.�݌ɑg�DID
  ) RETURN NUMBER                    -- ����Ȗڕʖ�ID
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_disposition_id_2'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_disposition_id2  mtl_generic_dispositions.disposition_id%TYPE; -- ����Ȗڕʖ�ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- ����Ȗڕʖ�ID�擾
    -- ====================================================
    SELECT mgd.disposition_id AS disposition_id     -- ����Ȗڕʖ�ID
    INTO   lt_disposition_id2
    FROM   mtl_generic_dispositions mgd             -- ����Ȗڕʖ��e�[�u��
    WHERE  mgd.segment1        = iv_dept_code       -- ����R�[�h
    AND    mgd.segment2        = iv_inv_account_kbn -- ���o�ɋ敪
    AND    mgd.organization_id = in_organization_id -- �݌ɑg�DID
    ;
--
    -- �߂�l�Ɋ���Ȗڕʖ�ID��ݒ肵�܂�
    RETURN lt_disposition_id2;
--
  EXCEPTION
    -- �擾�Ɏ��s�����ꍇ�ANULL��߂��܂�
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_disposition_id_2;
--
--###########################   END   ##############################
--
END XXCOI_COMMON_PKG;
/
