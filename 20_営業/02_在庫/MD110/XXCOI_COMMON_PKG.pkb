CREATE OR REPLACE PACKAGE BODY XXCOI_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI_COMMON_PKG(body)
 * Description      : ���ʊ֐��p�b�P�[�W(�݌�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COI
 * Version          : 1.12
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  ORG_ACCT_PERIOD_CHK        �݌ɉ�v���ԃ`�F�b�N
 *  GET_ORGANIZATION_ID        �݌ɑg�DID�擾
 *  GET_BELONGING_BASE         �������_�R�[�h�擾1
 *  GET_BASE_CODE              �������_�R�[�h�擾2
 *  GET_BELONGING_BASE2        �������_�R�[�h�擾3
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
 *  GET_BASE_AFF_ACTIVE_DATE   ���_AFF����K�p�J�n���擾
 *  GET_SUBINV_AFF_ACTIVE_DATE �ۊǏꏊAFF����K�p�J�n���擾
 *  CHK_AFF_ACTIVE             AFF����`�F�b�N
 *  CRE_LOT_TRX_TEMP           ���b�g�ʎ��TEMP�쐬
 *  DEL_LOT_TRX_TEMP           ���b�g�ʎ��TEMP�폜
 *  CRE_LOT_TRX                ���b�g�ʎ�����׍쐬
 *  GET_CUSTOMER_ID            �ڋq���o�i�󒍃A�h�I���j
 *  GET_PARENT_CHILD_ITEM_INFO �i�ڃR�[�h���o�i�e�^�q�j
 *  INS_UPD_LOT_HOLD_INFO      ���b�g���ێ��}�X�^���f
 *  INS_UPD_DEL_LOT_ONHAND     ���b�g�ʎ莝���ʔ��f
 *  GET_FRESH_CONDITION_DATE   �N�x��������Z�o
 *  GET_RESERVED_QUANTITY      �����\���Z�o
 *  GET_FRESH_CONDITION_DATE_F �N�x��������Z�o(�t�@���N�V�����^)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/23    1.0   T.Nishikawa      �V�K�쐬
 *  2009/03/13    1.1   H.Wada           get_subinventory_info1 �擾�����C��(��Q�ԍ�T1_0040)
 *  2009/03/30    1.2   N.Abe            convert_cust_subinv_code �ڋq�X�e�[�^�X�s���Ή�(��Q�ԍ�T1_0165)
 *  2009/04/09    1.3   H.Sasaki         [T1_0380]���ɑ��ڋq�R�[�h�̖߂�l�ݒ�
 *  2009/04/24    1.4   T.Nakamura       [T1_0630]�q�ɕۊǏꏊ�ϊ��ŁA���X���c�̕ۊǏꏊ�R�[�h�̌n�ɑΉ�
 *  2009/04/30    1.5   T.Nakamura       �ŏI�s�Ƀo�b�N�X���b�V����ǉ�
 *  2009/04/30    1.5   T.Nakamura       �ŏI�s�Ƀo�b�N�X���b�V����ǉ�
 *  2009/05/18    1.6   T.Nakamura       [T1_1044]HHT�q�ɕۊǏꏊ�R�[�h�̎擾�����ύX
 *  2009/06/03    1.7   H.Sasaki         [T1_1287][T1_1288]�A�T�C�����g�̗L�����������ɒǉ�
 *  2009/09/30    1.8   N.Abe            [E_T3_00616]�A�T�C�������g�̗L�����������ɒǉ�
 *  2010/03/23    1.9   Y.Goto           [E_�{�ғ�_01943]AFF����K�p�J�n���擾��ǉ�
 *  2010/03/29    1.10  Y.Goto           [E_�{�ғ�_01943]AFF����`�F�b�N��ǉ�
 *  2011/11/01    1.11  T.Yoshimoto      [E_�{�ғ�_07570]�������_�R�[�h�擾3��ǉ�
 *  2014/11/07    1.12  Y.Nagasue        [E_�{�ғ�_12237]�q�ɊǗ��V�X�e���Ή� �ȉ��̊֐���V�K�쐬
 *                                        ���b�g�ʎ��TEMP�쐬�A���b�g�ʎ��TEMP�폜�A���b�g�ʎ�����ׁA
 *                                        �ڋq���o�i�󒍃A�h�I���j�A�i�ڃR�[�h���o�i�e�^�q�j�A
 *                                        ���b�g���ێ��}�X�^���f�A���b�g�ʎ莝���ʔ��f�A
 *                                        �N�x��������Z�o�A�����\���Z�o�A�N�x��������Z�o(�t�@���N�V�����^)
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
-- == 2009/09/30 V1.8 Added START ===============================================================
      AND    TRUNC(id_target_date) BETWEEN TRUNC(aaf.effective_start_date)
      AND    TRUNC(NVL(aaf.effective_end_date,id_target_date))
-- == 2009/09/30 V1.8 Added END   ===============================================================
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
      SELECT  CASE
                WHEN aaf.ass_attribute2 IS NULL                   -- ���ߓ�
                  THEN aaf.ass_attribute5
                WHEN TO_DATE(aaf.ass_attribute2,'YYYYMMDD') > ld_target_date
                  THEN aaf.ass_attribute6                         -- ���_�R�[�h�i���j
                  ELSE aaf.ass_attribute5                         -- ���_�R�[�h�i�V�j
              END  AS base_code
      INTO    lv_base_code                                        -- �����_�R�[�h
      FROM    fnd_user                 fnu                        -- ���[�U�[�}�X�^
             ,per_all_people_f         apf                        -- �]�ƈ��}�X�^
             ,per_all_assignments_f    aaf                        -- �]�ƈ������}�X�^(�A�T�C�����g)
             ,per_person_types         ppt                        -- �]�ƈ��敪�}�X�^
      WHERE   fnu.user_id            = ln_user_id                 -- FND_GLOBAL.USER_ID
      AND     apf.person_id          = fnu.employee_id
      AND     TRUNC(ld_target_date) BETWEEN TRUNC(apf.effective_start_date)
      AND     TRUNC(NVL(apf.effective_end_date,ld_target_date))
-- == 2009/06/03 V1.7 Added START ===============================================================
      AND     TRUNC(ld_target_date) BETWEEN TRUNC(aaf.effective_start_date)
      AND     TRUNC(NVL(aaf.effective_end_date,ld_target_date))
-- == 2009/06/03 V1.7 Added END   ===============================================================
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
-- == 2009/04/24 Ver1.4 Modified START ============================================
--    cv_msg_coi_10207       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10207';             -- MSG�F�ۊǏꏊ�����G���[
--    cv_tkn_subinv_code     CONSTANT VARCHAR2(13) := 'SUB_INV_CODE';                 -- TKN�F�ۊǏꏊ����
--    cv_warehouse_div       CONSTANT VARCHAR2(1)  := 'A';                            -- �q�Ɏ��ʎq
    cv_whse_code_whse      CONSTANT VARCHAR2(1)  := '1';                            -- �q��
    cv_whse_code_store     CONSTANT VARCHAR2(1)  := '4';                            -- ���X
    cv_msg_coi_10380       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10380';             -- MSG�F�ۊǏꏊ�����G���[
    cv_tkn_dept_code       CONSTANT VARCHAR2(10) := 'DEPT_CODE';                    -- TKN�F���_����
    cv_tkn_whouse_code     CONSTANT VARCHAR2(11) := 'WHOUSE_CODE';                  -- TKN�F�q�ɺ���
-- == 2009/04/24 Ver1.4 Modified END ============================================
    -- *** ���[�J���ϐ� ***
-- == 2009/04/24 Ver1.4 Deleted START =========================================
--    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;            -- �ۊǏꏊ������
-- == 2009/04/24 Ver1.4 Deleted END =========================================
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
-- == 2009/05/18 V1.6 Modified START ===============================================================
--    SELECT 
--             msi.secondary_inventory_name   AS secondary_inventory_name -- 1.�ۊǏꏊ�R�[�h
--            ,msi.attribute7                 AS base_code                -- 2.���_�R�[�h
---- == 2009/04/24 Ver1.4 Deleted START =========================================
----            ,msi.disable_date               AS disable_date             -- 3.������
---- == 2009/04/24 Ver1.4 Deleted END =========================================
--            ,msi.attribute5                 AS subinv_div               -- 4.�I���Ώ�
--    INTO
--             ov_subinv_code                                             -- 1.�ۊǏꏊ�R�[�h
--            ,ov_base_code                                               -- 2.���_�R�[�h
---- == 2009/04/24 Ver1.4 Deleted START =========================================
----            ,lt_disable_date                                            -- 3.������
---- == 2009/04/24 Ver1.4 Deleted END =========================================
--            ,ov_subinv_div                                              -- 4.�I���Ώ�
--    FROM    mtl_secondary_inventories msi 
---- == 2009/04/24 Ver1.4 Modified START =========================================
----    WHERE   msi.secondary_inventory_name    = cv_warehouse_div||iv_base_code||iv_warehouse_code
--    WHERE   msi.attribute7                             =  iv_base_code
--    AND     SUBSTRB(msi.secondary_inventory_name, -2)  =  iv_warehouse_code
--    AND     msi.attribute1                             IN ( cv_whse_code_whse, cv_whse_code_store )
--    AND     TRUNC( NVL(msi.disable_date, SYSDATE+1 ) ) >  TRUNC( SYSDATE )
---- == 2009/04/24 Ver1.4 Modified END =========================================
--    AND     msi.organization_id             = in_organization_id;
--
    SELECT 
             msi.secondary_inventory_name   AS secondary_inventory_name -- 1.�ۊǏꏊ�R�[�h
            ,msi.attribute7                 AS base_code                -- 2.���_�R�[�h
            ,msi.attribute5                 AS subinv_div               -- 4.�I���Ώ�
    INTO
             ov_subinv_code                                             -- 1.�ۊǏꏊ�R�[�h
            ,ov_base_code                                               -- 2.���_�R�[�h
            ,ov_subinv_div                                              -- 4.�I���Ώ�
    FROM    mtl_secondary_inventories msi
    WHERE   SUBSTRB(msi.secondary_inventory_name, 2, 4) =  iv_base_code
    AND     SUBSTRB(msi.secondary_inventory_name, -2)   =  iv_warehouse_code
    AND     msi.attribute1                              IN ( cv_whse_code_whse, cv_whse_code_store )
    AND     TRUNC( NVL(msi.disable_date, SYSDATE+1 ) )  >  TRUNC( SYSDATE )
    AND     msi.organization_id                         =  in_organization_id;
-- == 2009/05/18 V1.6 Modified END   ===============================================================
    --
-- == 2009/04/24 Ver1.4 Deleted START =========================================
--    IF lt_disable_date IS NOT NULL 
--        AND TRUNC(lt_disable_date) <= TRUNC(SYSDATE) 
--    THEN
--    --
--        RAISE disable_date_expt;
--    --
--    END IF;
-- == 2009/04/24 Ver1.4 Deleted END =========================================
  --
  EXCEPTION
  --
-- == 2009/04/24 Ver1.4 Deleted START =========================================
--    WHEN disable_date_expt THEN
--        ov_errmsg  := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_msg_kbn_coi
--                  ,iv_name         => cv_msg_coi_10207
--                  ,iv_token_name1  => cv_tkn_subinv_code
--                  ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
--                      );
--        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
--        ov_retcode := cv_status_warn;
--    --
-- == 2009/04/24 Ver1.4 Deleted END =========================================
    WHEN NO_DATA_FOUND THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10206
-- == 2009/04/24 Ver1.4 Modified START =========================================
--                        ,iv_token_name1  => cv_tkn_subinv_code
--                        ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_base_code
                        ,iv_token_name2  => cv_tkn_whouse_code
                        ,iv_token_value2 => iv_warehouse_code
-- == 2009/04/24 Ver1.4 Modified END =========================================
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
-- == 2009/04/24 Ver1.4 Added START ============================================
    WHEN TOO_MANY_ROWS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10380
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_base_code
                        ,iv_token_name2  => cv_tkn_whouse_code
                        ,iv_token_value2 => iv_warehouse_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
-- == 2009/04/24 Ver1.4 Added END ============================================
    WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10206
-- == 2009/04/24 Ver1.4 Modified START =========================================
--                        ,iv_token_name1  => cv_tkn_subinv_code
--                        ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_base_code
                        ,iv_token_name2  => cv_tkn_whouse_code
                        ,iv_token_value2 => iv_warehouse_code
-- == 2009/04/24 Ver1.4 Modified END =========================================
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
-- == 2009/03/30 Ver1.2 Modified START =========================================
--        IF iv_record_type = cv_record_type_inv THEN         -- 90:�I��
--        --
--            IF lt_cust_status NOT IN( cv_cust_status_appl      -- 30:���F
--                                     ,cv_cust_status_cust      -- 40:�ڋq
--                                     ,cv_cust_status_rest      -- 50:�x�~
--                                     ,cv_cust_status_credit )  -- 80:�X����
--            THEN
--            --
--                lv_errmsg  := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_msg_kbn_coi
--                          ,iv_name         => cv_msg_coi_10216
--                          ,iv_token_name1  => cv_tkn_cust_code
--                          ,iv_token_value1 => iv_cust_code
--                              );
--                lv_errbuf := SQLERRM;
--                RAISE sub_error_expt;
--            --
--            END IF;
--        --
--        ELSE
--        --
--            IF ( ( iv_hht_form_flag IS NOT NULL ) AND ( iv_hht_form_flag = cv_flag_y ) ) THEN
--                -- HHT������͉�ʂ̏ꍇ
--                IF lt_cust_status NOT IN( cv_cust_status_appl      -- 30:���F
--                                         ,cv_cust_status_cust      -- 40:�ڋq
--                                         ,cv_cust_status_rest      -- 50:�x�~
--                                         ,cv_cust_status_credit )  -- 80:�X����
--                THEN
--                --
--                    lv_errmsg  := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_coi
--                              ,iv_name         => cv_msg_coi_10216
--                              ,iv_token_name1  => cv_tkn_cust_code
--                              ,iv_token_value1 => iv_cust_code
--                                  );
--                    lv_errbuf := SQLERRM;
--                    RAISE sub_error_expt;
--                --
--                END IF;
--            --
--            ELSE
--                -- HHT_IF�̏ꍇ
                -- ��l�ȊO�̏ꍇ
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
--            END IF;
--        --
--        END IF;
--    --
-- == 2009/03/30 Ver1.2 Modified END =========================================
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
-- == 2009/04/09 V1.3 Added START ===============================================================
        -- ���ɑ��ڋq�R�[�h���Z�b�g
        ov_inside_cust_code := iv_inside_code;
-- == 2009/04/09 V1.3 Added END   ===============================================================
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
-- == 2010/03/23 V1.9 Added START ===============================================================
/************************************************************************
 * Procedure Name  : GET_BASE_AFF_ACTIVE_DATE
 * Description     : ���_�R�[�h����AFF����̓K�p�J�n�����擾����B
 ************************************************************************/
  PROCEDURE get_base_aff_active_date(
    iv_base_code             IN  VARCHAR2   -- ���_�R�[�h
   ,od_start_date_active     OUT DATE       -- �K�p�J�n��
   ,ov_errbuf                OUT VARCHAR2   -- �G���[���b�Z�[�W
   ,ov_retcode               OUT VARCHAR2   -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg                OUT VARCHAR2   -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    cv_prg_name CONSTANT VARCHAR2(99) := 'get_base_aff_active_date';
  BEGIN
    IF (iv_base_code IS NULL) THEN
      ov_retcode := cv_status_error;    -- �ُ�:2
    ELSE
      ov_retcode := cv_status_normal;   -- ����:0
      -- ====================================================
      -- �K�p�J�n���擾
      -- ====================================================
      SELECT ffv.start_date_active AS start_date_active      -- �K�p�J�n��
      INTO   od_start_date_active
      FROM   fnd_flex_value_sets           ffvs              -- �L�[�t���b�N�X�i�Z�b�g�j
            ,fnd_flex_values               ffv               -- �L�[�t���b�N�X�i�l�j
      WHERE  ffvs.flex_value_set_id    = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name  = 'XX03_DEPARTMENT'
      AND    ffv.enabled_flag          = 'Y'
      AND    ffv.flex_value            = iv_base_code
      ;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_base_aff_active_date;
--
/************************************************************************
 * Procedure Name  : GET_SUBINV_AFF_ACTIVE_DATE
 * Description     : �ۊǏꏊ�R�[�h����AFF����̓K�p�J�n�����擾����B
 ************************************************************************/
  PROCEDURE get_subinv_aff_active_date(
    in_organization_id       IN  NUMBER     -- �݌ɑg�DID
   ,iv_subinv_code           IN  VARCHAR2   -- �ۊǏꏊ�R�[�h
   ,od_start_date_active     OUT DATE       -- �K�p�J�n��
   ,ov_errbuf                OUT VARCHAR2   -- �G���[���b�Z�[�W
   ,ov_retcode               OUT VARCHAR2   -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg                OUT VARCHAR2   -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    cv_prg_name CONSTANT VARCHAR2(99) := 'get_subinv_aff_active_date';
  BEGIN
    IF (in_organization_id IS NULL) OR (iv_subinv_code IS NULL) THEN
      ov_retcode := cv_status_error;    -- �ُ�:2
    ELSE
      ov_retcode := cv_status_normal;   -- ����:0
      -- ====================================================
      -- �K�p�J�n���擾
      -- ====================================================
      SELECT ffv.start_date_active AS start_date_active      -- �K�p�J�n��
      INTO   od_start_date_active
      FROM   mtl_secondary_inventories     msi               -- �ۊǏꏊ�}�X�^
            ,fnd_flex_value_sets           ffvs              -- �L�[�t���b�N�X�i�Z�b�g�j
            ,fnd_flex_values               ffv               -- �L�[�t���b�N�X�i�l�j
      WHERE  ffvs.flex_value_set_id       = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name     = 'XX03_DEPARTMENT'
      AND    ffv.enabled_flag             = 'Y'
      AND    ffv.flex_value               = msi.attribute7
      AND    msi.organization_id          = in_organization_id
      AND    msi.secondary_inventory_name = iv_subinv_code
      ;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_subinv_aff_active_date;
--
-- == 2010/03/23 V1.9 Added END   ===============================================================
-- == 2010/03/29 V1.10 Added START ===============================================================
/************************************************************************
 * Function Name   : CHK_AFF_ACTIVE
 * Description     : AFF����̎g�p�\�`�F�b�N���s���܂��B
 ************************************************************************/
  FUNCTION chk_aff_active(
      in_organization_id      IN  NUMBER      -- �݌ɑg�DID
    , iv_base_code            IN  VARCHAR2    -- ���_�R�[�h
    , iv_subinv_code          IN  VARCHAR2    -- �ۊǏꏊ�R�[�h
    , id_target_date          IN  DATE        -- �Ώۓ�
  ) RETURN VARCHAR2                           -- �`�F�b�N����
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'chk_aff_active'; -- �v���O������
    cv_y         CONSTANT VARCHAR2(1)  := 'Y';               -- �g�p�\
    cv_n         CONSTANT VARCHAR2(1)  := 'N';               -- �g�p�s��
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ld_start_date_active      fnd_flex_values.start_date_active%TYPE; -- �K�p�J�n��
--
  BEGIN
--
    -- ====================================================
    -- AFF����擾
    -- ====================================================
    IF (iv_base_code IS NOT NULL) THEN
      -- ���_�R�[�h���g�p�s���m�F
      SELECT  ffv.start_date_active         start_date_active --  �K���J�n��
      INTO    ld_start_date_active
      FROM    fnd_flex_value_sets           ffvs              --  �L�[�t���b�N�X�i�Z�b�g�j
            , fnd_flex_values               ffv               --  �L�[�t���b�N�X�i�l�j
      WHERE   ffvs.flex_value_set_id      =   ffv.flex_value_set_id
      AND     ffvs.flex_value_set_name    =   'XX03_DEPARTMENT'
      AND     ffv.enabled_flag            =   'Y'
      AND     ffv.flex_value              =   iv_base_code
      ;
      --
      IF  (ld_start_date_active IS NULL) THEN
        -- �K���J�n��NULL�̏ꍇ�A�g�p�\
        RETURN  cv_y;
      ELSIF (ld_start_date_active   <=  id_target_date) THEN
        -- �Ώۓ����K���J�n���ȍ~�̏ꍇ�A�g�p�\
        RETURN  cv_y;
      ELSE
        -- �Ώۓ����K���J�n�����O�̏ꍇ�A�g�p�s��
        RETURN  cv_n;
      END IF;
      --
    ELSIF (iv_subinv_code IS NOT NULL) THEN
      -- �ۊǏꏊ�R�[�h���g�p�s���m�F
      SELECT  ffv.start_date_active AS start_date_active      -- �K�p�J�n��
      INTO    ld_start_date_active
      FROM    mtl_secondary_inventories     msi               -- �ۊǏꏊ�}�X�^
            , fnd_flex_value_sets           ffvs              -- �L�[�t���b�N�X�i�Z�b�g�j
            , fnd_flex_values               ffv               -- �L�[�t���b�N�X�i�l�j
      WHERE   ffvs.flex_value_set_id        =   ffv.flex_value_set_id
      AND     ffvs.flex_value_set_name      =   'XX03_DEPARTMENT'
      AND     ffv.enabled_flag              =   'Y'
      AND     ffv.flex_value                =   msi.attribute7
      AND     msi.organization_id           =   in_organization_id
      AND     msi.secondary_inventory_name  =   iv_subinv_code
      ;
      --
      IF  (ld_start_date_active IS NULL) THEN
        -- �K���J�n��NULL�̏ꍇ�A�g�p�\
        RETURN  cv_y;
      ELSIF (ld_start_date_active   <=  id_target_date) THEN
        -- �Ώۓ����K���J�n���ȍ~�̏ꍇ�A�g�p�\
        RETURN  cv_y;
      ELSE
        -- �Ώۓ����K���J�n�����O�̏ꍇ�A�g�p�s��
        RETURN  cv_n;
      END IF;
      --
    ELSE
      -- ���_�A�ۊǏꏊ���Ƃ���NULL�̏ꍇ�A�g�p�s��
      RETURN cv_n;
      --
    END IF;

--
  EXCEPTION
    -- NOTFOUND, TOO_MANY_ROWS���͎g�p�s��
    WHEN OTHERS THEN
      RETURN cv_n;
--
  END chk_aff_active;
--
-- == 2010/03/29 V1.10 Added END   ===============================================================
-- 2011/11/01 T.Yoshimoto v1.11 Add Start E_�{�ғ�_07570
/************************************************************************
 * Procedure Name  : GET_BELONGING_BASE2
 * Description     : �c�ƈ��ɕR�t���������_�R�[�h���擾����B
 ************************************************************************/
  PROCEDURE get_belonging_base2(
    in_employee_code  IN  VARCHAR2        -- �c�ƈ��R�[�h
   ,id_target_date    IN  DATE            -- �Ώۓ�
   ,ov_base_code      OUT VARCHAR2        -- ���_�R�[�h
   ,ov_errbuf         OUT VARCHAR2        -- �G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2        -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg         OUT VARCHAR2        -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(99) := 'get_belonging_base2';
    -- *** ���[�J���萔 ***
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    cv_date_format CONSTANT VARCHAR2(8) := 'YYYYMMDD';
    cv_employee    CONSTANT VARCHAR2(8) := 'EMPLOYEE';              -- �J�e�S���F�]�ƈ�
    cv_emp         CONSTANT VARCHAR2(3) := 'EMP';
    cv_y           CONSTANT VARCHAR2(1) := 'Y';
--
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ���_�R�[�h������
    ov_base_code := NULL;
--
    -- �c�ƈ��R�[�h��NULL�܂��́A�Ώۓ���NULL�̏ꍇ
    IF ( ( in_employee_code IS NULL ) OR ( id_target_date IS NULL ) ) THEN
      ov_retcode := cv_status_error;    -- �ُ�:2
--
    ELSE
--
      SELECT CASE
               WHEN aaf.ass_attribute2 IS NULL              -- ���ߓ�
                 THEN aaf.ass_attribute5
               WHEN TO_DATE(aaf.ass_attribute2,cv_date_format) > id_target_date
                 THEN aaf.ass_attribute6                    -- ���_�R�[�h�i���j
               ELSE aaf.ass_attribute5                      -- ���_�R�[�h�i�V�j
             END  AS base_code
      INTO   ov_base_code                                   -- �����_�R�[�h
      FROM   per_all_people_f         apf                   -- �]�ƈ��}�X�^
            ,per_all_assignments_f    aaf                   -- �]�ƈ������}�X�^(�A�T�C�����g)
            ,per_person_types         ppt                   -- �]�ƈ��敪�}�X�^
            ,jtf_rs_salesreps         jrs
            ,jtf_rs_resource_extns    jrre
      WHERE  TRUNC(id_target_date) BETWEEN TRUNC(apf.effective_start_date)
          AND  TRUNC(NVL(apf.effective_end_date,id_target_date))
        AND  TRUNC(id_target_date) BETWEEN TRUNC(aaf.effective_start_date)
          AND  TRUNC(NVL(aaf.effective_end_date,id_target_date))
        AND  ppt.business_group_id  = cn_business_group_id
        AND  ppt.system_person_type = cv_emp
        AND  ppt.active_flag        = cv_y
        AND  apf.person_type_id     = ppt.person_type_id
        AND  aaf.person_id          = apf.person_id
        AND  apf.person_id          = jrre.source_id
        AND  jrre.category          = cv_employee
        AND  jrre.resource_id       = jrs.resource_id
        AND  jrs.salesrep_number    = in_employee_code
      ;
      --
      IF (ov_base_code IS NULL) THEN
        ov_retcode := cv_status_error;    -- �ُ�:2
      END IF;
--
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_belonging_base2;
-- 2011/11/01 T.Yoshimoto v1.11 Add End
-- == 2014/11/07 Ver1.5 Y.Nagasue ADD START ======================================================
/************************************************************************
 * Procedure Name  : CRE_LOT_TRX_TEMP
 * Description     : ���b�g�ʎ��TEMP�쐬
 ************************************************************************/
  PROCEDURE cre_lot_trx_temp(
    in_trx_set_id       IN  NUMBER   -- ����Z�b�gID
   ,iv_parent_item_code IN  VARCHAR2 -- �e�i�ڃR�[�h
   ,iv_child_item_code  IN  VARCHAR2 -- �q�i�ڃR�[�h
   ,iv_lot              IN  VARCHAR2 -- ���b�g(�ܖ�����)
   ,iv_diff_sum_code    IN  VARCHAR2 -- �ŗL�L��
   ,iv_trx_type_code    IN  VARCHAR2 -- ����^�C�v�R�[�h
   ,id_trx_date         IN  DATE     -- �����
   ,iv_slip_num         IN  VARCHAR2 -- �`�[No
   ,in_case_in_qty      IN  NUMBER   -- ����
   ,in_case_qty         IN  NUMBER   -- �P�[�X��
   ,in_singly_qty       IN  NUMBER   -- �o����
   ,in_summary_qty      IN  NUMBER   -- �������
   ,iv_base_code        IN  VARCHAR2 -- ���_�R�[�h
   ,iv_subinv_code      IN  VARCHAR2 -- �ۊǏꏊ�R�[�h
   ,iv_tran_subinv_code IN  VARCHAR2 -- �]����ۊǏꏊ�R�[�h
   ,iv_tran_loc_code    IN  VARCHAR2 -- �]���惍�P�[�V�����R�[�h
   ,iv_inout_code       IN  VARCHAR2 -- ���o�ɃR�[�h
   ,iv_source_code      IN  VARCHAR2 -- �\�[�X�R�[�h
   ,iv_relation_key     IN  VARCHAR2 -- �R�t���L�[
   ,on_trx_id           OUT NUMBER   -- ���b�g��TEMP���ID
   ,ov_errbuf           OUT VARCHAR2 -- �G���[���b�Z�[�W
   ,ov_retcode          OUT VARCHAR2 -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg           OUT VARCHAR2 -- ���[�U�[�E�G���[���b�Z�[�W
  )IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'cre_lot_trx_temp'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�W�p�萔
    cv_msg_kbn_coi          CONSTANT VARCHAR2(5)   := 'XXCOI';            -- �A�v���P�[�V�����Z�k��
    cv_err_msg_xxcoi1_10477 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10477'; -- ���ʊ֐��p�����[�^�K�{�G���[
    cv_err_msg_xxcoi1_10478 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10478'; -- �P�[�X���E�o���������`�F�b�N�G���[
    cv_err_msg_xxcoi1_10479 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10479'; -- ������ʃ`�F�b�N�G���[
    cv_err_msg_xxcoi1_00005 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
    cv_err_msg_xxcoi1_10470 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10470'; -- �}�X�^�g�D�擾�G���[
    cv_err_msg_xxcoi1_00006 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
    cv_err_msg_xxcoi1_10480 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10480'; -- �i��ID�擾�G���[
    cv_err_msg_xxcoi1_10481 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10481'; -- ���P�[�V�����擾�G���[
    cv_err_msg_xxcoi1_10507 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10507'; -- ����0�ȉ��G���[
--
    cv_msg_xxcoi1_10493     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10493'; -- ���b�g�ʎ��TEMP�쐬
    cv_msg_xxcoi1_10496     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10496'; -- �e�i�ڃR�[�h
    cv_msg_xxcoi1_10497     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10497'; -- ����^�C�v�R�[�h
    cv_msg_xxcoi1_10498     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10498'; -- �����
    cv_msg_xxcoi1_10499     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10499'; -- �`�[No
    cv_msg_xxcoi1_10500     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10500'; -- ����
    cv_msg_xxcoi1_10501     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10501'; -- �������
    cv_msg_xxcoi1_10502     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10502'; -- ���_�R�[�h
    cv_msg_xxcoi1_10503     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10503'; -- �ۊǏꏊ�R�[�h
    cv_msg_xxcoi1_10504     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10504'; -- �\�[�X�R�[�h
    cv_msg_xxcoi1_10505     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10505'; -- �R�t���L�[
--
    cv_msg_tkn_param1       CONSTANT VARCHAR2(20)  := 'PARAM1';           -- �g�[�N���F�p�����[�^�P
    cv_msg_tkn_param2       CONSTANT VARCHAR2(20)  := 'PARAM2';           -- �g�[�N���F�p�����[�^�Q
    cv_msg_tkn_pro_tok      CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- �g�[�N���F�v���t�@�C����
    cv_msg_tkn_org_code_tok CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';     -- �g�[�N���F�݌ɑg�D�R�[�h
    cv_msg_tkn_item_code    CONSTANT VARCHAR2(20)  := 'ITEM_CODE';        -- �g�[�N���F�i�ڃR�[�h
    cv_msg_tkn_subinv_code  CONSTANT VARCHAR2(20)  := 'SUBINV_CODE';      -- �g�[�N���F�ۊǏꏊ�R�[�h
--
    -- �v���t�@�C��
    cv_xxcoi1_organization_code
                            CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE'; -- �݌ɑg�D�R�[�h
--
    -- �Q�ƃ^�C�v
    cv_xxcoi1_tran_type     CONSTANT VARCHAR2(30)  := 'XXCOI1_TRANSACTION_TYPE_NAME';   -- ���[�U�[��`����^�C�v����
    cv_xxcoi1_lot_tran_type CONSTANT VARCHAR2(30)  := 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'; -- ���b�g�ʎ���\������^�C�v��
--
    -- ����^�C�v�R�[�h
    cv_trx_type_code_10     CONSTANT VARCHAR2(2)   := '10'; -- ���o��
    cv_trx_type_code_20     CONSTANT VARCHAR2(2)   := '20'; -- �q��
    cv_trx_type_code_70     CONSTANT VARCHAR2(2)   := '70'; -- ����VD��[
--
    -- �\�[�X�R�[�h�l
    cv_invttmtx             CONSTANT VARCHAR2(15)  := 'INVTTMTX';     -- ���̑�������͉��
    cv_xxcoi016a06c         CONSTANT VARCHAR2(15)  := 'XXCOI016A06C'; -- ���b�g�ʏo�׏��쐬
--
    -- SQL�g�p�萔
    cv_flag_y               CONSTANT VARCHAR2(1)   := 'Y'; -- �t���O:Y
    ct_lang                 CONSTANT fnd_lookup_values.language%TYPE                 := USERENV('LANG'); -- ����
    ct_priority_1           CONSTANT xxcoi_mst_warehouse_location.priority%TYPE      := 1;               -- �D�揇�ʁF���C�����P�[�V����
    ct_location_type_3      CONSTANT xxcoi_mst_warehouse_location.location_type%TYPE := '3';             -- ���P�[�V�����^�C�v�F�_�~�[���P�[�V����
--
--
    -- *** ���[�J���ϐ� ***
    -- ���̓p�����[�^�i�[�p�ϐ�
    lt_trx_set_id        xxcoi_lot_transactions_temp.transaction_set_id%TYPE;      -- ����Z�b�gID
    lt_parent_item_code  mtl_system_items_b.segment1%TYPE;                         -- �e�i�ڃR�[�h
    lt_child_item_code   mtl_system_items_b.segment1%TYPE;                         -- �q�i�ڃR�[�h
    lt_lot               xxcoi_lot_transactions_temp.lot%TYPE;                     -- ���b�g(�ܖ�����)
    lt_diff_sum_code     xxcoi_lot_transactions_temp.difference_summary_code%TYPE; -- �ŗL�L��
    lt_trx_type_code     xxcoi_lot_transactions_temp.transaction_type_code%TYPE;   -- ����^�C�v�R�[�h
    lt_trx_date          xxcoi_lot_transactions_temp.transaction_date%TYPE;        -- �����
    lt_slip_num          xxcoi_lot_transactions_temp.slip_num%TYPE;                -- �`�[No
    lt_case_in_qty       xxcoi_lot_transactions_temp.case_in_qty%TYPE;             -- ����
    lt_case_qty          xxcoi_lot_transactions_temp.case_qty%TYPE;                -- �P�[�X��
    lt_singly_qty        xxcoi_lot_transactions_temp.singly_qty%TYPE;              -- �o����
    lt_summary_qty       xxcoi_lot_transactions_temp.summary_qty%TYPE;             -- �������
    lt_base_code         xxcoi_lot_transactions_temp.base_code%TYPE;               -- ���_�R�[�h
    lt_subinv_code       xxcoi_lot_transactions_temp.subinventory_code%TYPE;       -- �ۊǏꏊ�R�[�h
    lt_tran_subinv_code  xxcoi_lot_transactions_temp.transfer_subinventory%TYPE;   -- �]����ۊǏꏊ�R�[�h
    lt_tran_loc_code     xxcoi_lot_transactions_temp.transfer_location_code%TYPE;  -- �]���惍�P�[�V�����R�[�h
    lt_sign_div          xxcoi_lot_transactions_temp.sign_div%TYPE;                -- �����敪
    lt_source_code       xxcoi_lot_transactions_temp.source_code%TYPE;             -- �\�[�X�R�[�h
    lt_relation_key      xxcoi_lot_transactions_temp.relation_key%TYPE;            -- �R�t���L�[
--
    -- ID�ϊ��A���o����
    lt_org_code          mtl_parameters.organization_code%TYPE;           -- �݌ɑg�D�R�[�h
    lt_org_id            mtl_parameters.organization_id%TYPE;             -- �݌ɑg�DID
    lt_parent_item_id    xxcoi_lot_transactions_temp.parent_item_id%TYPE; -- �e�i��ID
    lt_child_item_id     xxcoi_lot_transactions_temp.child_item_id%TYPE;  -- �q�i��ID
    lt_loc_code          xxcoi_lot_transactions_temp.location_code%TYPE;  -- ���P�[�V�����R�[�h
    lt_trx_id            xxcoi_lot_transactions_temp.transaction_id%TYPE; -- ���ID
--
    -- ���b�Z�[�W�i�[�p�ϐ�
    lv_msg_proc_name     VARCHAR2(100); -- �v���V�[�W����
    lv_msg_chk_tkn       VARCHAR2(100); -- ���̓p�����[�^�G���[�g�[�N���i�[�p�ϐ�
--
    -- ���̑�
    lv_inout_code        VARCHAR2(3); -- ���o�ɃR�[�h
    ln_trx_num_chk       NUMBER;      -- ������ʃ`�F�b�N�p�ϐ�
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    -- ���̓p�����[�^�i�[�p�ϐ�
    lt_trx_set_id           := NULL; -- ����Z�b�gID
    lt_parent_item_code     := NULL; -- �e�i�ڃR�[�h
    lt_child_item_code      := NULL; -- �q�i�ڃR�[�h
    lt_lot                  := NULL; -- ���b�g(�ܖ�����)
    lt_diff_sum_code        := NULL; -- �ŗL�L��
    lt_trx_type_code        := NULL; -- ����^�C�v�R�[�h
    lt_trx_date             := NULL; -- �����
    lt_slip_num             := NULL; -- �`�[No
    lt_case_in_qty          := NULL; -- ����
    lt_case_qty             := NULL; -- �P�[�X��
    lt_singly_qty           := NULL; -- �o����
    lt_summary_qty          := NULL; -- �������
    lt_base_code            := NULL; -- ���_�R�[�h
    lt_subinv_code          := NULL; -- �ۊǏꏊ�R�[�h
    lt_tran_subinv_code     := NULL; -- �]����ۊǏꏊ�R�[�h
    lt_tran_loc_code        := NULL; -- �]���惍�P�[�V�����R�[�h
    lt_sign_div             := NULL; -- �����敪
    lt_source_code          := NULL; -- �\�[�X�R�[�h
    lt_relation_key         := NULL; -- �R�t���L�[
--
    -- SQL���o����
    lt_org_code             := NULL; -- �݌ɑg�D�R�[�h
    lt_org_id               := NULL; -- �݌ɑg�DID
    lt_parent_item_id       := NULL; -- �e�i��ID
    lt_child_item_id        := NULL; -- �q�i��ID
    lt_loc_code             := NULL; -- ���P�[�V�����R�[�h
    lt_trx_id               := NULL; -- ���ID
--
    -- ���b�Z�[�W�i�[�p�ϐ�
    lv_msg_proc_name        := NULL; -- �v���V�[�W����
    lv_msg_chk_tkn          := NULL; -- ���̓p�����[�^�G���[�g�[�N���i�[�p�ϐ�
--
    -- ���̑�
    lv_inout_code           := NULL; -- ���o�ɃR�[�h
    ln_trx_num_chk          := NULL; -- ������ʃ`�F�b�N�p�ϐ�
--
    -- �v���V�[�W�����擾
    lv_msg_proc_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10493
                        );
--
    -- ======================================
    -- �P�F���̓p�����[�^�̃`�F�b�N
    -- ======================================
    -- �e�i�ڃR�[�h
    IF ( iv_parent_item_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10496
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����^�C�v�R�[�h
    IF ( iv_trx_type_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10497
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �����
    IF ( id_trx_date IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10498
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �`�[No
    IF ( iv_slip_num IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10499
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����
    IF ( in_case_in_qty IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10500
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �������
    IF ( in_summary_qty IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10501
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���_�R�[�h
    IF ( iv_base_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10502
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ۊǏꏊ�R�[�h
    IF ( iv_subinv_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10503
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �\�[�X�R�[�h
    IF ( iv_source_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10504
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �R�t���L�[
    IF ( iv_relation_key IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10505
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- IN�p�����[�^��ϐ��ɑޔ�
    lt_trx_set_id       := in_trx_set_id;       -- ����Z�b�gID
    lt_parent_item_code := iv_parent_item_code; -- �e�i�ڃR�[�h
    lt_child_item_code  := iv_child_item_code;  -- �q�i�ڃR�[�h
    lt_lot              := iv_lot;              -- ���b�g(�ܖ�����)
    lt_diff_sum_code    := iv_diff_sum_code;    -- �ŗL�L��
    lt_trx_type_code    := iv_trx_type_code;    -- ����^�C�v�R�[�h
    lt_trx_date         := id_trx_date;         -- �����
    lt_slip_num         := iv_slip_num;         -- �`�[No
    lt_case_in_qty      := in_case_in_qty;      -- ����
    lt_case_qty         := in_case_qty;         -- �P�[�X��
    lt_singly_qty       := in_singly_qty;       -- �o����
    lt_summary_qty      := in_summary_qty;      -- �������
    lt_base_code        := iv_base_code;        -- ���_�R�[�h
    lt_subinv_code      := iv_subinv_code;      -- �ۊǏꏊ�R�[�h
    lt_tran_subinv_code := iv_tran_subinv_code; -- �]����ۊǏꏊ�R�[�h
    lt_tran_loc_code    := iv_tran_loc_code;    -- �]���惍�P�[�V�����R�[�h
    lv_inout_code       := iv_inout_code;       -- ���o�ɃR�[�h
    lt_source_code      := iv_source_code;      -- �\�[�X�R�[�h
    lt_relation_key     := iv_relation_key;     -- �R�t���L�[
--
    -- �����A�P�[�X���A�o�����A������ʂ̌���
    -- �P�[�X����NULL�̏ꍇ��0��ݒ�
    IF ( lt_case_qty IS NULL ) THEN
      lt_case_qty := 0;
    END IF;
--
    -- �o������NULL�̏ꍇ��0��ݒ�
    IF ( lt_singly_qty IS NULL ) THEN
      lt_singly_qty := 0;
    END IF;
--
    -- ������0�ȉ��̏ꍇ�́A�G���[
    IF ( lt_case_in_qty <= 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10507
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/*
    -- �P�[�X���A�o�����̕����`�F�b�N
    -- �������قȂ�ꍇ�̓G���[
    IF ( (lt_case_qty >= 0 AND lt_singly_qty >= 0) OR (lt_case_qty <= 0 AND lt_singly_qty <= 0) ) THEN
      NULL;
    ELSE
     lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10478
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
*/
--
    -- (�������P�[�X��)�{�o������������ʂƈقȂ�ꍇ�̓G���[
    ln_trx_num_chk := ( lt_case_in_qty * lt_case_qty ) + lt_singly_qty;
    IF ( lt_summary_qty <> ln_trx_num_chk ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10479
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- WHO�J�����擾
    -- �Œ�O���[�o���ϐ����g�p���邽�ߊ���
--
    -- �v���t�@�C���uXXCOI:�݌ɑg�D�R�[�h�v���擾
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    lt_org_code := FND_PROFILE.VALUE( cv_xxcoi1_organization_code );
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00005
                     ,iv_token_name1  => cv_msg_tkn_pro_tok
                     ,iv_token_value1 => cv_xxcoi1_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- �Q�FID�ϊ��A�擾
    -- ======================================
    -- ���ʊ֐����g�p���A�݌ɑg�DID���擾
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    lt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => lt_org_code
                 );
    IF ( lt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00006
                     ,iv_token_name1  => cv_msg_tkn_org_code_tok
                     ,iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �e�i��ID�擾
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    BEGIN
      SELECT msib.inventory_item_id inventory_item_id
      INTO   lt_parent_item_id
      FROM   mtl_system_items_b msib                    -- Disc�i�ڃ}�X�^
      WHERE  msib.segment1        = lt_parent_item_code -- �e�i�ڃR�[�h
      AND    msib.organization_id = lt_org_id           -- �݌ɑg�DID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10480
                       ,iv_token_name1  => cv_msg_tkn_org_code_tok
                       ,iv_token_value1 => lt_org_code
                       ,iv_token_name2  => cv_msg_tkn_item_code
                       ,iv_token_value2 => lt_parent_item_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �q�i��ID�擾
    -- NULL�̏ꍇ�͏������s��Ȃ�
    IF ( lt_child_item_code IS NULL ) THEN
      NULL;
    ELSE
      -- �q�i��ID���擾
      -- �擾�ł��Ȃ��ꍇ�̓G���[
      BEGIN
        SELECT msib.inventory_item_id inventory_item_id
        INTO   lt_child_item_id
        FROM   mtl_system_items_b msib                   -- Disc�i�ڃ}�X�^
        WHERE  msib.segment1        = lt_child_item_code -- �q�i�ڃR�[�h
        AND    msib.organization_id = lt_org_id          -- �݌ɑg�DID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_err_msg_xxcoi1_10480
                         ,iv_token_name1  => cv_msg_tkn_org_code_tok
                         ,iv_token_value1 => lt_org_code
                         ,iv_token_name2  => cv_msg_tkn_item_code
                         ,iv_token_value2 => lt_child_item_code
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    -- ���P�[�V�����R�[�h�擾
    -- �q�i�ڃR�[�h��NULL�A�܂��́A���b�g�ʏo�׏��쐬����N���̏ꍇ�͏������s��Ȃ�
    IF ( ( lt_child_item_code IS NULL ) OR ( lt_source_code = cv_xxcoi016a06c ) ) THEN
      NULL;
    ELSE
      -- ���C�����P�[�V�������擾
      -- �擾�ł��Ȃ������ꍇ�́A�_�~�[���P�[�V�������擾
      BEGIN
        SELECT xmwl.location_code location_code
        INTO   lt_loc_code
        FROM   xxcoi_mst_warehouse_location xmwl         -- �q�Ƀ��P�[�V�����}�X�^
        WHERE  xmwl.organization_id   = lt_org_id        -- �݌ɑg�DID
        AND    xmwl.base_code         = lt_base_code     -- ���_�R�[�h
        AND    xmwl.subinventory_code = lt_subinv_code   -- �ۊǏꏊ�R�[�h
        AND    xmwl.child_item_id     = lt_child_item_id -- �q�i��ID
        AND    xmwl.priority          = ct_priority_1    -- �D�揇�ʁF�P�i���C�����P�[�V�����j
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �_�~�[���P�[�V�������擾
          -- �擾�ł��Ȃ������ꍇ�̓G���[
          BEGIN
            SELECT xmwl.location_code location_code
            INTO   lt_loc_code
            FROM   xxcoi_mst_warehouse_location xmwl            -- �q�Ƀ��P�[�V�����}�X�^
            WHERE  xmwl.organization_id   = lt_org_id           -- �݌ɑg�DID
            AND    xmwl.base_code         = lt_base_code        -- ���_�R�[�h
            AND    xmwl.subinventory_code = lt_subinv_code      -- �ۊǏꏊ�R�[�h
            AND    xmwl.location_type     = ct_location_type_3  -- ���P�[�V�����^�C�v�F�_�~�[���P�[�V����
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_coi
                             ,iv_name         => cv_err_msg_xxcoi1_10481
                             ,iv_token_name1  => cv_msg_tkn_org_code_tok
                             ,iv_token_value1 => lt_org_code
                             ,iv_token_name2  => cv_msg_tkn_subinv_code
                             ,iv_token_value2 => lt_subinv_code
                             ,iv_token_name3  => cv_msg_tkn_item_code
                             ,iv_token_value3 => lt_child_item_code
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
      END;
    END IF;
--
    -- �����擾
    -- ���o�ɁA�q�ցA����VD��[�̏ꍇ
    IF ( lt_trx_type_code IN ( cv_trx_type_code_10, cv_trx_type_code_20, cv_trx_type_code_70 ) ) THEN
      SELECT flv.attribute2    AS attribute2 -- �����敪
      INTO   lt_sign_div
      FROM   fnd_lookup_values flv --�Q�ƃ^�C�v
      WHERE  flv.lookup_type  = cv_xxcoi1_lot_tran_type
      AND    flv.lookup_code  = lv_inout_code
      AND    flv.language     = ct_lang
      AND    flv.enabled_flag = cv_flag_y
      AND    lt_trx_date      BETWEEN NVL(flv.start_date_active, lt_trx_date)
                              AND     NVL(flv.end_date_active  , lt_trx_date)
      ;
    -- ��L�ȊO�̏ꍇ
    ELSE
      SELECT flv.attribute2    AS attribute2 -- �����敪
      INTO   lt_sign_div
      FROM   fnd_lookup_values flv --�Q�ƃ^�C�v
      WHERE  flv.lookup_type  = cv_xxcoi1_tran_type
      AND    flv.lookup_code  = lt_trx_type_code
      AND    flv.language     = ct_lang
      AND    flv.enabled_flag = cv_flag_y
      AND    lt_trx_date      BETWEEN NVL(flv.start_date_active, lt_trx_date)
                              AND     NVL(flv.end_date_active  , lt_trx_date)
      ;
    END IF;
--
    -- ======================================
    -- �R�F���b�g�ʎ��TEMP�o�^�A�X�V
    -- ======================================
    -- ���݃`�F�b�N
    BEGIN
      SELECT xltt.transaction_id transaction_id
      INTO   lt_trx_id
      FROM   xxcoi_lot_transactions_temp xltt              -- ���b�g�ʎ��TEMP
      WHERE  xltt.transaction_type_code = lt_trx_type_code -- ����^�C�v�R�[�h
      AND    xltt.source_code           = lt_source_code   -- �\�[�X�R�[�h
      AND    xltt.relation_key          = lt_relation_key  -- �R�t���L�[
      AND    xltt.base_code             = lt_base_code     -- ���_�R�[�h
      AND    xltt.subinventory_code     = lt_subinv_code   -- �ۊǏꏊ�R�[�h
      AND    xltt.organization_id       = lt_org_id        -- �݌ɑg�DID
      AND    xltt.source_code           = cv_invttmtx      -- ���̑�������
      ;
--
      -- ���݂���ꍇ�́A�X�V
      UPDATE xxcoi_lot_transactions_temp
      SET    transaction_set_id        = lt_trx_set_id                    -- ����Z�b�gID
            ,organization_id           = lt_org_id                        -- �݌ɑg�DID
            ,parent_item_id            = lt_parent_item_id                -- �e�i��ID
            ,child_item_id             = lt_child_item_id                 -- �q�i��ID
            ,lot                       = lt_lot                           -- ���b�g
            ,difference_summary_code   = lt_diff_sum_code                 -- �ŗL�L��
            ,transaction_month         = TO_CHAR( lt_trx_date, 'YYYYMM' ) -- ����N��
            ,transaction_date          = lt_trx_date                      -- �����
            ,slip_num                  = lt_slip_num                      -- �`�[No
            ,case_in_qty               = lt_case_in_qty                   -- ����
            ,case_qty                  = lt_case_qty                      -- �P�[�X��
            ,singly_qty                = lt_singly_qty                    -- �o����
            ,summary_qty               = lt_summary_qty                   -- �������
            ,base_code                 = lt_base_code                     -- ���_�R�[�h
            ,subinventory_code         = lt_subinv_code                   -- �ۊǏꏊ�R�[�h
            ,location_code             = lt_loc_code                      -- ���P�[�V�����R�[�h
            ,transfer_organization_id  = DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id )
                                                                          -- �]����݌ɑg�DID
            ,transfer_subinventory     = lt_tran_subinv_code              -- �]����ۊǏꏊ�R�[�h
            ,transfer_location_code    = lt_tran_loc_code                 -- �]���惍�P�[�V�����R�[�h
            ,last_updated_by           = cn_last_updated_by               -- �ŏI�X�V��
            ,last_update_date          = cd_last_update_date              -- �ŏI�X�V��
            ,last_update_login         = cn_last_update_login             -- �ŏI�X�V���O�C��
            ,request_id                = cn_request_id                    -- �v��ID
            ,program_application_id    = cn_program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                = cn_program_id                    -- �R���J�����g�E�v���O����ID
            ,program_update_date       = cd_program_update_date           -- �v���O�����X�V��
      WHERE  transaction_id            = lt_trx_id                        -- ���ID
      ;
--
    EXCEPTION
      -- ���݂��Ȃ��ꍇ�́A�V�K�쐬
      WHEN NO_DATA_FOUND THEN
--
        -- �V�[�P���X�l�擾
        SELECT xxcoi_lot_trx_temp_s01.NEXTVAL
        INTO   lt_trx_id
        FROM   DUAL
        ;
--
        IF ( lt_case_qty * lt_singly_qty >= 0 ) THEN
          -- �P�[�X���ƃo�����̕�������v����ꍇ�A���b�g�ʎ��TEMP��1�s�œo�^����B
          -- ���b�g�ʎ��TEMP�쐬
          INSERT INTO xxcoi_lot_transactions_temp(
             transaction_id                                       -- ���ID
            ,transaction_set_id                                   -- ����Z�b�gID
            ,organization_id                                      -- �݌ɑg�DID
            ,parent_item_id                                       -- �e�i��ID
            ,child_item_id                                        -- �q�i��ID
            ,lot                                                  -- ���b�g
            ,difference_summary_code                              -- �ŗL�L��
            ,transaction_type_code                                -- ����^�C�v�R�[�h
            ,transaction_month                                    -- ����N��
            ,transaction_date                                     -- �����
            ,slip_num                                             -- �`�[No
            ,case_in_qty                                          -- ����
            ,case_qty                                             -- �P�[�X��
            ,singly_qty                                           -- �o����
            ,summary_qty                                          -- �������
            ,transaction_uom                                      -- ��P��
            ,primary_quantity                                     -- ��P�ʐ���
            ,base_code                                            -- ���_�R�[�h
            ,subinventory_code                                    -- �ۊǏꏊ�R�[�h
            ,location_code                                        -- ���P�[�V�����R�[�h
            ,transfer_organization_id                             -- �]����݌ɑg�DID
            ,transfer_subinventory                                -- �]����ۊǏꏊ�R�[�h
            ,transfer_location_code                               -- �]���惍�P�[�V�����R�[�h
            ,sign_div                                             -- �����敪
            ,source_code                                          -- �\�[�X�R�[�h
            ,relation_key                                         -- �R�t���L�[
            ,created_by                                           -- �쐬��
            ,creation_date                                        -- �쐬��
            ,last_updated_by                                      -- �ŏI�X�V��
            ,last_update_date                                     -- �ŏI�X�V��
            ,last_update_login                                    -- �ŏI�X�V���O�C��
            ,request_id                                           -- �v��ID
            ,program_application_id                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                                           -- �R���J�����g�E�v���O����ID
            ,program_update_date                                  -- �v���O�����X�V��
          )VALUES(
             lt_trx_id                                            -- ���ID
            ,lt_trx_set_id                                        -- ����Z�b�gID
            ,lt_org_id                                            -- �݌ɑg�DID
            ,lt_parent_item_id                                    -- �e�i��ID
            ,lt_child_item_id                                     -- �q�i��ID
            ,lt_lot                                               -- ���b�g
            ,lt_diff_sum_code                                     -- �ŗL�L��
            ,lt_trx_type_code                                     -- ����^�C�v�R�[�h
            ,TO_CHAR( lt_trx_date, 'YYYYMM' )                     -- ����N��
            ,lt_trx_date                                          -- �����
            ,lt_slip_num                                          -- �`�[No
            ,lt_case_in_qty                                       -- ����
            ,lt_case_qty                                          -- �P�[�X��
            ,lt_singly_qty                                        -- �o����
            ,lt_summary_qty                                       -- �������
            ,NULL                                                 -- ��P��
            ,NULL                                                 -- ��P�ʐ���
            ,lt_base_code                                         -- ���_�R�[�h
            ,lt_subinv_code                                       -- �ۊǏꏊ�R�[�h
            ,lt_loc_code                                          -- ���P�[�V�����R�[�h
            ,DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id ) -- �]����݌ɑg�DID
            ,lt_tran_subinv_code                                  -- �]����ۊǏꏊ�R�[�h
            ,lt_tran_loc_code                                     -- �]���惍�P�[�V�����R�[�h
            ,lt_sign_div                                          -- �����敪
            ,lt_source_code                                       -- �\�[�X�R�[�h
            ,lt_relation_key                                      -- �R�t���L�[
            ,cn_created_by                                        -- �쐬��
            ,cd_creation_date                                     -- �쐬��
            ,cn_last_updated_by                                   -- �ŏI�X�V��
            ,cd_last_update_date                                  -- �ŏI�X�V��
            ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
            ,cn_request_id                                        -- �v��ID
            ,cn_program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,cn_program_id                                        -- �R���J�����g�E�v���O����ID
            ,cd_program_update_date                               -- �v���O�����X�V��
          );
        ELSE
          -- �P�[�X���ƃo�����̕������قȂ�ꍇ�A���b�g�ʎ��TEMP��2�s�ɕ����ēo�^����B
          -- ���b�g�ʎ��TEMP�쐬
          INSERT INTO xxcoi_lot_transactions_temp(
             transaction_id                                       -- ���ID
            ,transaction_set_id                                   -- ����Z�b�gID
            ,organization_id                                      -- �݌ɑg�DID
            ,parent_item_id                                       -- �e�i��ID
            ,child_item_id                                        -- �q�i��ID
            ,lot                                                  -- ���b�g
            ,difference_summary_code                              -- �ŗL�L��
            ,transaction_type_code                                -- ����^�C�v�R�[�h
            ,transaction_month                                    -- ����N��
            ,transaction_date                                     -- �����
            ,slip_num                                             -- �`�[No
            ,case_in_qty                                          -- ����
            ,case_qty                                             -- �P�[�X��
            ,singly_qty                                           -- �o����
            ,summary_qty                                          -- �������
            ,transaction_uom                                      -- ��P��
            ,primary_quantity                                     -- ��P�ʐ���
            ,base_code                                            -- ���_�R�[�h
            ,subinventory_code                                    -- �ۊǏꏊ�R�[�h
            ,location_code                                        -- ���P�[�V�����R�[�h
            ,transfer_organization_id                             -- �]����݌ɑg�DID
            ,transfer_subinventory                                -- �]����ۊǏꏊ�R�[�h
            ,transfer_location_code                               -- �]���惍�P�[�V�����R�[�h
            ,sign_div                                             -- �����敪
            ,source_code                                          -- �\�[�X�R�[�h
            ,relation_key                                         -- �R�t���L�[
            ,created_by                                           -- �쐬��
            ,creation_date                                        -- �쐬��
            ,last_updated_by                                      -- �ŏI�X�V��
            ,last_update_date                                     -- �ŏI�X�V��
            ,last_update_login                                    -- �ŏI�X�V���O�C��
            ,request_id                                           -- �v��ID
            ,program_application_id                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                                           -- �R���J�����g�E�v���O����ID
            ,program_update_date                                  -- �v���O�����X�V��
          )VALUES(
             lt_trx_id                                            -- ���ID
            ,lt_trx_set_id                                        -- ����Z�b�gID
            ,lt_org_id                                            -- �݌ɑg�DID
            ,lt_parent_item_id                                    -- �e�i��ID
            ,lt_child_item_id                                     -- �q�i��ID
            ,lt_lot                                               -- ���b�g
            ,lt_diff_sum_code                                     -- �ŗL�L��
            ,lt_trx_type_code                                     -- ����^�C�v�R�[�h
            ,TO_CHAR( lt_trx_date, 'YYYYMM' )                     -- ����N��
            ,lt_trx_date                                          -- �����
            ,lt_slip_num                                          -- �`�[No
            ,lt_case_in_qty                                       -- ����
            ,lt_case_qty                                          -- �P�[�X��
            ,0                                                    -- �o����
            ,lt_case_in_qty * lt_case_qty                         -- �������
            ,NULL                                                 -- ��P��
            ,NULL                                                 -- ��P�ʐ���
            ,lt_base_code                                         -- ���_�R�[�h
            ,lt_subinv_code                                       -- �ۊǏꏊ�R�[�h
            ,lt_loc_code                                          -- ���P�[�V�����R�[�h
            ,DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id ) -- �]����݌ɑg�DID
            ,lt_tran_subinv_code                                  -- �]����ۊǏꏊ�R�[�h
            ,lt_tran_loc_code                                     -- �]���惍�P�[�V�����R�[�h
            ,lt_sign_div                                          -- �����敪
            ,lt_source_code                                       -- �\�[�X�R�[�h
            ,lt_relation_key                                      -- �R�t���L�[
            ,cn_created_by                                        -- �쐬��
            ,cd_creation_date                                     -- �쐬��
            ,cn_last_updated_by                                   -- �ŏI�X�V��
            ,cd_last_update_date                                  -- �ŏI�X�V��
            ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
            ,cn_request_id                                        -- �v��ID
            ,cn_program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,cn_program_id                                        -- �R���J�����g�E�v���O����ID
            ,cd_program_update_date                               -- �v���O�����X�V��
          );
--
          -- �V�[�P���X�l�擾
          SELECT xxcoi_lot_trx_temp_s01.NEXTVAL
          INTO   lt_trx_id
          FROM   DUAL
          ;
--
          -- ���b�g�ʎ��TEMP�쐬
          INSERT INTO xxcoi_lot_transactions_temp(
             transaction_id                                       -- ���ID
            ,transaction_set_id                                   -- ����Z�b�gID
            ,organization_id                                      -- �݌ɑg�DID
            ,parent_item_id                                       -- �e�i��ID
            ,child_item_id                                        -- �q�i��ID
            ,lot                                                  -- ���b�g
            ,difference_summary_code                              -- �ŗL�L��
            ,transaction_type_code                                -- ����^�C�v�R�[�h
            ,transaction_month                                    -- ����N��
            ,transaction_date                                     -- �����
            ,slip_num                                             -- �`�[No
            ,case_in_qty                                          -- ����
            ,case_qty                                             -- �P�[�X��
            ,singly_qty                                           -- �o����
            ,summary_qty                                          -- �������
            ,transaction_uom                                      -- ��P��
            ,primary_quantity                                     -- ��P�ʐ���
            ,base_code                                            -- ���_�R�[�h
            ,subinventory_code                                    -- �ۊǏꏊ�R�[�h
            ,location_code                                        -- ���P�[�V�����R�[�h
            ,transfer_organization_id                             -- �]����݌ɑg�DID
            ,transfer_subinventory                                -- �]����ۊǏꏊ�R�[�h
            ,transfer_location_code                               -- �]���惍�P�[�V�����R�[�h
            ,sign_div                                             -- �����敪
            ,source_code                                          -- �\�[�X�R�[�h
            ,relation_key                                         -- �R�t���L�[
            ,created_by                                           -- �쐬��
            ,creation_date                                        -- �쐬��
            ,last_updated_by                                      -- �ŏI�X�V��
            ,last_update_date                                     -- �ŏI�X�V��
            ,last_update_login                                    -- �ŏI�X�V���O�C��
            ,request_id                                           -- �v��ID
            ,program_application_id                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                                           -- �R���J�����g�E�v���O����ID
            ,program_update_date                                  -- �v���O�����X�V��
          )VALUES(
             lt_trx_id                                            -- ���ID
            ,lt_trx_set_id                                        -- ����Z�b�gID
            ,lt_org_id                                            -- �݌ɑg�DID
            ,lt_parent_item_id                                    -- �e�i��ID
            ,lt_child_item_id                                     -- �q�i��ID
            ,lt_lot                                               -- ���b�g
            ,lt_diff_sum_code                                     -- �ŗL�L��
            ,lt_trx_type_code                                     -- ����^�C�v�R�[�h
            ,TO_CHAR( lt_trx_date, 'YYYYMM' )                     -- ����N��
            ,lt_trx_date                                          -- �����
            ,lt_slip_num                                          -- �`�[No
            ,lt_case_in_qty                                       -- ����
            ,0                                                    -- �P�[�X��
            ,lt_singly_qty                                        -- �o����
            ,lt_singly_qty                                        -- �������
            ,NULL                                                 -- ��P��
            ,NULL                                                 -- ��P�ʐ���
            ,lt_base_code                                         -- ���_�R�[�h
            ,lt_subinv_code                                       -- �ۊǏꏊ�R�[�h
            ,lt_loc_code                                          -- ���P�[�V�����R�[�h
            ,DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id ) -- �]����݌ɑg�DID
            ,lt_tran_subinv_code                                  -- �]����ۊǏꏊ�R�[�h
            ,lt_tran_loc_code                                     -- �]���惍�P�[�V�����R�[�h
            ,lt_sign_div                                          -- �����敪
            ,lt_source_code                                       -- �\�[�X�R�[�h
            ,lt_relation_key                                      -- �R�t���L�[
            ,cn_created_by                                        -- �쐬��
            ,cd_creation_date                                     -- �쐬��
            ,cn_last_updated_by                                   -- �ŏI�X�V��
            ,cd_last_update_date                                  -- �ŏI�X�V��
            ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
            ,cn_request_id                                        -- �v��ID
            ,cn_program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,cn_program_id                                        -- �R���J�����g�E�v���O����ID
            ,cd_program_update_date                               -- �v���O�����X�V��
          );
      END IF;
--
    END;
--
    -- OUT�p�����[�^�Ɏ擾�������ID��ݒ�
    on_trx_id := lt_trx_id;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END cre_lot_trx_temp;
--
/************************************************************************
 * Procedure Name  : DEL_LOT_TRX_TEMP
 * Description     : ���b�g�ʎ��TEMP�폜
 ************************************************************************/
  PROCEDURE del_lot_trx_temp(
    in_trx_id  IN  NUMBER          -- ���b�g��TEMP���ID
   ,ov_errbuf  OUT VARCHAR2        -- �G���[���b�Z�[�W
   ,ov_retcode OUT VARCHAR2        -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg  OUT VARCHAR2        -- ���[�U�[�E�G���[���b�Z�[�W
  )IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'del_lot_trx_temp'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�W�p�萔
    cv_msg_kbn_coi          CONSTANT VARCHAR2(5)   := 'XXCOI';            -- �A�v���P�[�V�����Z�k��
    cv_err_msg_xxcoi1_10477 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10477'; -- ���ʊ֐��p�����[�^�K�{�G���[
    cv_msg_xxcoi1_10494     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10494'; -- �v���V�[�W�����F���b�g�ʎ��TEMP�폜
    cv_msg_xxcoi1_10506     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10506'; -- ���ID
--
    cv_msg_tkn_param1       CONSTANT VARCHAR2(20)  := 'PARAM1';           -- �g�[�N���F�p�����[�^�P
    cv_msg_tkn_param2       CONSTANT VARCHAR2(20)  := 'PARAM2';           -- �g�[�N���F�p�����[�^�Q
-- 
    -- *** ���[�J���ϐ� ***
    -- ���̓p�����[�^�i�[�p�ϐ�
    lt_trx_id          xxcoi_lot_transactions_temp.transaction_id%TYPE; -- ���ID
--
    -- ���b�Z�[�W�i�[�p�ϐ�
    lv_msg_proc_name VARCHAR2(100); -- �v���V�[�W����
    lv_msg_chk_tkn   VARCHAR2(100); -- ���̓p�����[�^�G���[�g�[�N���i�[�p�ϐ�
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
--
    -- ���̓p�����[�^�i�[�p�ϐ�
    lt_trx_id        := NULL; -- ���ID
--
    -- ���b�Z�[�W�i�[�p�ϐ�
    lv_msg_proc_name := NULL; -- �v���V�[�W����
    lv_msg_chk_tkn   := NULL; -- ���̓p�����[�^�G���[�g�[�N���i�[�p�ϐ�
--
    -- �v���V�[�W�����擾
    lv_msg_proc_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10494
                        );
--
--
    -- ======================================
    -- �P�F���̓p�����[�^�̃`�F�b�N
    -- ======================================
    -- ���ID
    IF ( in_trx_id IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10506
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^��ϐ��ɑޔ�
    lt_trx_id := in_trx_id; -- ���ID
--
    -- ======================================
    -- �Q�F���b�g�ʎ��TEMP�폜
    -- ======================================
    DELETE 
    FROM   xxcoi_lot_transactions_temp xltt
    WHERE  transaction_id = lt_trx_id      -- ���ID
    ;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END del_lot_trx_temp;
--
/************************************************************************
 * Procedure Name  : CRE_LOT_TRX
 * Description     : ���b�g�ʎ�����׍쐬
 ************************************************************************/
  PROCEDURE cre_lot_trx(
    in_trx_set_id            IN  NUMBER   -- ����Z�b�gID
   ,iv_parent_item_code      IN  VARCHAR2 -- �e�i�ڃR�[�h
   ,iv_child_item_code       IN  VARCHAR2 -- �q�i�ڃR�[�h
   ,iv_lot                   IN  VARCHAR2 -- ���b�g(�ܖ�����)
   ,iv_diff_sum_code         IN  VARCHAR2 -- �ŗL�L��
   ,iv_trx_type_code         IN  VARCHAR2 -- ����^�C�v�R�[�h
   ,id_trx_date              IN  DATE     -- �����
   ,iv_slip_num              IN  VARCHAR2 -- �`�[No
   ,in_case_in_qty           IN  NUMBER   -- ����
   ,in_case_qty              IN  NUMBER   -- �P�[�X��
   ,in_singly_qty            IN  NUMBER   -- �o����
   ,in_summary_qty           IN  NUMBER   -- �������
   ,iv_base_code             IN  VARCHAR2 -- ���_�R�[�h
   ,iv_subinv_code           IN  VARCHAR2 -- �ۊǏꏊ�R�[�h
   ,iv_loc_code              IN  VARCHAR2 -- ���P�[�V�����R�[�h
   ,iv_tran_subinv_code      IN  VARCHAR2 -- �]����ۊǏꏊ�R�[�h
   ,iv_tran_loc_code         IN  VARCHAR2 -- �]���惍�P�[�V�����R�[�h
   ,iv_source_code           IN  VARCHAR2 -- �\�[�X�R�[�h
   ,iv_relation_key          IN  VARCHAR2 -- �R�t���L�[
   ,iv_reason                IN  VARCHAR2 -- ���R
   ,iv_reserve_trx_type_code IN  VARCHAR2 -- ����������^�C�v�R�[�h
   ,on_trx_id                OUT NUMBER   -- ���b�g�ʎ������
   ,ov_errbuf                OUT VARCHAR2 -- �G���[���b�Z�[�W
   ,ov_retcode               OUT VARCHAR2 -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg                OUT VARCHAR2 -- ���[�U�[�E�G���[���b�Z�[�W
  )IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'cre_lot_trx'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�W�p�萔
    cv_msg_kbn_coi          CONSTANT VARCHAR2(5)   := 'XXCOI';            -- �A�v���P�[�V�����Z�k��
    cv_err_msg_xxcoi1_10477 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10477'; -- ���ʊ֐��p�����[�^�K�{�G���[
    cv_err_msg_xxcoi1_10478 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10478'; -- �P�[�X���E�o���������`�F�b�N�G���[
    cv_err_msg_xxcoi1_10479 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10479'; -- ������ʃ`�F�b�N�G���[
    cv_err_msg_xxcoi1_00005 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
    cv_err_msg_xxcoi1_00006 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
    cv_err_msg_xxcoi1_10480 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10480'; -- �i��ID�擾�G���[
    cv_err_msg_xxcoi1_10482 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10482'; -- �i�ڏ��擾�G���[
    cv_err_msg_xxcoi1_10483 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10483'; -- ���Z�㐔�ʎ擾�G���[
    cv_err_msg_xxcoi1_10484 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10484'; -- �]�ƈ����擾�G���[
    cv_err_msg_xxcoi1_10507 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10507'; -- ����0�ȉ��G���[
    cv_err_msg_xxcoi1_00011 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- �Ɩ����t���擾�G���[
--
    cv_msg_xxcoi1_10495     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10495'; -- �v���V�[�W���F���b�g�ʎ�����׍쐬
    cv_msg_xxcoi1_10496     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10496'; -- �e�i�ڃR�[�h
    cv_msg_xxcoi1_10497     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10497'; -- ����^�C�v�R�[�h
    cv_msg_xxcoi1_10498     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10498'; -- �����
    cv_msg_xxcoi1_10500     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10500'; -- ����
    cv_msg_xxcoi1_10501     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10501'; -- �������
    cv_msg_xxcoi1_10502     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10502'; -- ���_�R�[�h
    cv_msg_xxcoi1_10503     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10503'; -- �ۊǏꏊ�R�[�h
    cv_msg_xxcoi1_10504     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10504'; -- �\�[�X�R�[�h
--
    cv_msg_tkn_param1       CONSTANT VARCHAR2(20)  := 'PARAM1';           -- �g�[�N���F�p�����[�^�P
    cv_msg_tkn_param2       CONSTANT VARCHAR2(20)  := 'PARAM2';           -- �g�[�N���F�p�����[�^�Q
    cv_msg_tkn_pro_tok      CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- �g�[�N���F�v���t�@�C����
    cv_msg_tkn_org_code_tok CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';     -- �g�[�N���F�݌ɑg�D�R�[�h
    cv_msg_tkn_item_code    CONSTANT VARCHAR2(20)  := 'ITEM_CODE';        -- �g�[�N���F�i�ڃR�[�h
    cv_msg_tkn_err_msg      CONSTANT VARCHAR2(20)  := 'ERR_MSG';          -- �g�[�N���F�G���[���b�Z�[�W
    cv_msg_tkn_uom_code     CONSTANT VARCHAR2(20)  := 'UOM_CODE';         -- �g�[�N���F���Z�O�P��
--
    -- �v���t�@�C����
    cv_xxcoi1_organization_code CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE'; -- �v���t�@�C���F�݌ɑg�D�R�[�h
--
    -- *** ���[�J���ϐ� ***
    -- ���̓p�����[�^�i�[�p�ϐ�
    lt_trx_set_id            xxcoi_lot_transactions.transaction_set_id%TYPE;            -- ����Z�b�gID
    lt_parent_item_code      mtl_system_items_b.segment1%TYPE;                          -- �e�i�ڃR�[�h
    lt_child_item_code       mtl_system_items_b.segment1%TYPE;                          -- �q�i�ڃR�[�h
    lt_lot                   xxcoi_lot_transactions.lot%TYPE;                           -- ���b�g(�ܖ�����)
    lt_diff_sum_code         xxcoi_lot_transactions.difference_summary_code%TYPE;       -- �ŗL�L��
    lt_trx_type_code         xxcoi_lot_transactions.transaction_type_code%TYPE;         -- ����^�C�v�R�[�h
    lt_trx_date              xxcoi_lot_transactions.transaction_date%TYPE;              -- �����
    lt_slip_num              xxcoi_lot_transactions.slip_num%TYPE;                      -- �`�[No
    lt_case_in_qty           xxcoi_lot_transactions.case_in_qty%TYPE;                   -- ����
    lt_case_qty              xxcoi_lot_transactions.case_qty%TYPE;                      -- �P�[�X��
    lt_singly_qty            xxcoi_lot_transactions.singly_qty%TYPE;                    -- �o����
    lt_summary_qty           xxcoi_lot_transactions.summary_qty%TYPE;                   -- �������
    lt_base_code             xxcoi_lot_transactions.base_code%TYPE;                     -- ���_�R�[�h
    lt_subinv_code           xxcoi_lot_transactions.subinventory_code%TYPE;             -- �ۊǏꏊ�R�[�h
    lt_loc_code              xxcoi_lot_transactions.location_code%TYPE;                 -- ���P�[�V�����R�[�h
    lt_tran_subinv_code      xxcoi_lot_transactions.transfer_subinventory%TYPE;         -- �]����ۊǏꏊ�R�[�h
    lt_tran_loc_code         xxcoi_lot_transactions.transfer_location_code%TYPE;        -- �]���惍�P�[�V�����R�[�h
    lt_source_code           xxcoi_lot_transactions.source_code%TYPE;                   -- �\�[�X�R�[�h
    lt_relation_key          xxcoi_lot_transactions.relation_key%TYPE;                  -- �R�t���L�[
    lt_reason                xxcoi_lot_transactions.reason%TYPE;                        -- ���R
    lt_reserve_trx_type_code xxcoi_lot_transactions.reserve_transaction_type_code%TYPE; -- ����������^�C�v�R�[�h
--
    -- ID�ϊ��A���o����
    ld_proc_date       DATE;                                       -- �Ɩ����t
    lt_org_code        mtl_parameters.organization_code%TYPE;      -- �݌ɑg�D�R�[�h
    lt_org_id          mtl_parameters.organization_id%TYPE;        -- �݌ɑg�DID
    lt_parent_item_id  xxcoi_lot_transactions.parent_item_id%TYPE; -- �e�i��ID
    lt_trx_id          xxcoi_lot_transactions.transaction_id%TYPE; -- ���ID
    lt_fix_user_code   xxcoi_lot_transactions.fix_user_code%TYPE;  -- �m��҃R�[�h
    lt_fix_user_name   xxcoi_lot_transactions.fix_user_name%TYPE;  -- �m��Җ�
--
    -- ���ʊ֐��擾����
    -- �݌ɋ��ʊ֐��u�i�ڏ��擾2�v
    lt_item_status        mtl_system_items_b.inventory_item_status_code%TYPE;    -- �i�ڃX�e�[�^�X
    lt_cust_order_flg     mtl_system_items_b.customer_order_enabled_flag%TYPE;   -- �ڋq�󒍉\�t���O
    lt_transaction_enable mtl_system_items_b.mtl_transactions_enabled_flag%TYPE; -- ����\
    lt_stock_enabled_flg  mtl_system_items_b.stock_enabled_flag%TYPE;            -- �݌ɕۗL�\�t���O
    lt_return_enable      mtl_system_items_b.returnable_flag%TYPE;               -- �ԕi�\
    lt_sales_class        ic_item_mst_b.attribute26%TYPE;                        -- ����Ώۋ敪
    lt_primary_unit       mtl_system_items_b.primary_unit_of_measure%TYPE;       -- ��P��
    lt_child_item_id      xxcoi_lot_transactions.child_item_id%TYPE;             -- �q�i��ID
    lt_primary_uom_code   mtl_system_items_b.primary_uom_code%TYPE;              -- ��P�ʃR�[�h
--
    -- �̔����ʊ֐��u�P�ʊ��Z�擾�v
    lt_after_quantity xxcoi_lot_transactions.primary_quantity%TYPE; -- ���Z�㐔��
    ln_content        NUMBER;                                       -- ����
--
    -- ���b�Z�[�W�i�[�p�ϐ�
    lv_msg_proc_name VARCHAR2(100); -- �v���V�[�W����
    lv_msg_chk_tkn   VARCHAR2(100); -- ���̓p�����[�^�G���[�g�[�N���i�[�p�ϐ�
--
    -- ���̑�
    ln_trx_num_chk NUMBER; -- ������ʃ`�F�b�N�p�ϐ�
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    -- ���̓p�����[�^�i�[�p�ϐ�
    lt_trx_set_id            := NULL; -- ����Z�b�gID
    lt_parent_item_code      := NULL; -- �e�i�ڃR�[�h
    lt_child_item_code       := NULL; -- �q�i�ڃR�[�h
    lt_lot                   := NULL; -- ���b�g(�ܖ�����)
    lt_diff_sum_code         := NULL; -- �ŗL�L��
    lt_trx_type_code         := NULL; -- ����^�C�v�R�[�h
    lt_trx_date              := NULL; -- �����
    lt_slip_num              := NULL; -- �`�[No
    lt_case_in_qty           := NULL; -- ����
    lt_case_qty              := NULL; -- �P�[�X��
    lt_singly_qty            := NULL; -- �o����
    lt_summary_qty           := NULL; -- �������
    lt_base_code             := NULL; -- ���_�R�[�h
    lt_subinv_code           := NULL; -- �ۊǏꏊ�R�[�h
    lt_loc_code              := NULL; -- ���P�[�V�����R�[�h
    lt_tran_subinv_code      := NULL; -- �]����ۊǏꏊ�R�[�h
    lt_tran_loc_code         := NULL; -- �]���惍�P�[�V�����R�[�h
    lt_source_code           := NULL; -- �\�[�X�R�[�h
    lt_relation_key          := NULL; -- �R�t���L�[
    lt_reason                := NULL; -- ���R
    lt_reserve_trx_type_code := NULL; -- ����������^�C�v�R�[�h
--
    -- ID�ϊ��A���o����
    ld_proc_date             := NULL; -- �Ɩ����t
    lt_org_code              := NULL; -- �݌ɑg�D�R�[�h
    lt_org_id                := NULL; -- �݌ɑg�DID
    lt_parent_item_id        := NULL; -- �e�i��ID
    lt_trx_id                := NULL; -- ���ID
    lt_fix_user_code         := NULL; -- �m��҃R�[�h
    lt_fix_user_name         := NULL; -- �m��Җ�
--
    -- ���ʊ֐��擾����
    -- �݌ɋ��ʊ֐��u�i�ڏ��擾2�v
    lt_item_status           := NULL; -- �i�ڃX�e�[�^�X
    lt_cust_order_flg        := NULL; -- �ڋq�󒍉\�t���O
    lt_transaction_enable    := NULL; -- ����\
    lt_stock_enabled_flg     := NULL; -- �݌ɕۗL�\�t���O
    lt_return_enable         := NULL; -- �ԕi�\
    lt_sales_class           := NULL; -- ����Ώۋ敪
    lt_primary_unit          := NULL; -- ��P��
    lt_child_item_id         := NULL; -- �q�i��ID
    lt_primary_uom_code      := NULL; -- ��P�ʃR�[�h
--
    -- �̔����ʊ֐��u�P�ʊ��Z�擾�v
    lt_after_quantity        := NULL; -- ���Z�㐔��
    ln_content               := NULL; -- ����
--
    -- ���̑�
    ln_trx_num_chk           := NULL; -- ������ʃ`�F�b�N�p�ϐ�
--
    -- �v���V�[�W�����擾
    lv_msg_proc_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10495
                        );
--
    -- ======================================
    -- �P�F���̓p�����[�^�̃`�F�b�N
    -- ======================================
    -- �e�i�ڃR�[�h
    IF ( iv_parent_item_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10496
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����^�C�v�R�[�h
    IF ( iv_trx_type_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10497
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �����
    IF ( id_trx_date IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10498
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����
    IF ( in_case_in_qty IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10500
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �������
    IF ( in_summary_qty IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10501
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���_�R�[�h
    IF ( iv_base_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10502
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ۊǏꏊ�R�[�h
    IF ( iv_subinv_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10503
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �\�[�X�R�[�h
    IF ( iv_source_code IS NULL ) THEN
      -- �g�[�N���ݒ�l�擾
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10504
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- IN�p�����[�^��ϐ��ɑޔ�
    lt_trx_set_id            := in_trx_set_id;             -- ����Z�b�gID
    lt_parent_item_code      := iv_parent_item_code;       -- �e�i�ڃR�[�h
    lt_child_item_code       := iv_child_item_code;        -- �q�i�ڃR�[�h
    lt_lot                   := iv_lot;                    -- ���b�g(�ܖ�����)
    lt_diff_sum_code         := iv_diff_sum_code;          -- �ŗL�L��
    lt_trx_type_code         := iv_trx_type_code;          -- ����^�C�v�R�[�h
    lt_trx_date              := id_trx_date;               -- �����
    lt_slip_num              := iv_slip_num;               -- �`�[No
    lt_case_in_qty           := in_case_in_qty;            -- ����
    lt_case_qty              := in_case_qty;               -- �P�[�X��
    lt_singly_qty            := in_singly_qty;             -- �o����
    lt_summary_qty           := in_summary_qty;            -- �������
    lt_base_code             := iv_base_code;              -- ���_�R�[�h
    lt_subinv_code           := iv_subinv_code;            -- �ۊǏꏊ�R�[�h
    lt_loc_code              := iv_loc_code;               -- ���P�[�V�����R�[�h
    lt_tran_subinv_code      := iv_tran_subinv_code;       -- �]����ۊǏꏊ�R�[�h
    lt_tran_loc_code         := iv_tran_loc_code;          -- �]���惍�P�[�V�����R�[�h
    lt_source_code           := iv_source_code;            -- �\�[�X�R�[�h
    lt_relation_key          := iv_relation_key;           -- �R�t���L�[
    lt_reason                := iv_reason;                 -- ���R
    lt_reserve_trx_type_code := iv_reserve_trx_type_code ; -- ����������^�C�v�R�[�h
--
    -- �����A�P�[�X���A�o�����A������ʂ̌���
    -- �P�[�X����NULL�̏ꍇ��0��ݒ�
    IF ( lt_case_qty IS NULL ) THEN
      lt_case_qty := 0;
    END IF;
--
    -- �o������NULL�̏ꍇ��0��ݒ�
    IF ( lt_singly_qty IS NULL ) THEN
      lt_singly_qty := 0;
    END IF;
--
    -- ������0�ȉ��̏ꍇ�́A�G���[
    IF ( lt_case_in_qty <= 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10507
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �P�[�X���A�o�����̕����`�F�b�N
    -- �������قȂ�ꍇ�̓G���[
    IF ( ( lt_case_qty >= 0 AND lt_singly_qty >= 0 ) OR ( lt_case_qty <= 0 AND lt_singly_qty <= 0 ) ) THEN
      NULL;
    ELSE
     lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10478
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (�������P�[�X��)�{�o������������ʂƈقȂ�ꍇ�̓G���[
    ln_trx_num_chk := (lt_case_in_qty * lt_case_qty) + lt_singly_qty;
    IF ( lt_summary_qty <> ln_trx_num_chk ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10479
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- WHO�J�����擾
    -- �Œ�O���[�o���ϐ����g�p���邽�ߊ���
--
    -- �v���t�@�C���uXXCOI:�݌ɑg�D�R�[�h�v���擾
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    lt_org_code := FND_PROFILE.VALUE( cv_xxcoi1_organization_code );
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00005
                     ,iv_token_name1  => cv_msg_tkn_pro_tok
                     ,iv_token_value1 => cv_xxcoi1_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ɩ����t�擾
    -- �擾�ł��Ȃ��ꍇ�́A�G���[
    ld_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( ld_proc_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00011
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- �Q�FID�ϊ��A�擾
    -- ======================================
    -- ���ʊ֐����g�p���A�݌ɑg�DID���擾
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    lt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => lt_org_code
                 );
    IF ( lt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00006
                     ,iv_token_name1  => cv_msg_tkn_org_code_tok
                     ,iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �e�i��ID�擾
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    BEGIN
      SELECT msib.inventory_item_id inventory_item_id
      INTO   lt_parent_item_id
      FROM   mtl_system_items_b msib                    -- Disc�i�ڃ}�X�^
      WHERE  msib.segment1        = lt_parent_item_code -- �e�i�ڃR�[�h
      AND    msib.organization_id = lt_org_id           -- �݌ɑg�DID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10480
                       ,iv_token_name1  => cv_msg_tkn_org_code_tok
                       ,iv_token_value1 => lt_org_code
                       ,iv_token_name2  => cv_msg_tkn_item_code
                       ,iv_token_value2 => lt_parent_item_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �q�i��ID�擾
    -- NULL�̏ꍇ�͏������s��Ȃ�
    IF ( lt_child_item_code IS NULL ) THEN
      NULL;
    ELSE
      -- �q�i�ڂ̕i�ڏ����擾
      -- �݌ɋ��ʊ֐��u�i�ڏ��擾2�v
      xxcoi_common_pkg.get_item_info2(
        ov_errbuf               => lv_errbuf             -- �G���[���b�Z�[�W
       ,ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
       ,ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[���b�Z�[�W
       ,iv_item_code            => lt_child_item_code    -- IN�p�����[�^.�q�i�ڃR�[�h
       ,in_org_id               => lt_org_id             -- �݌ɑg�DID
       ,ov_item_status          => lt_item_status        -- ���g�p���Ȃ�_�i�ڃX�e�[�^�X
       ,ov_cust_order_flg       => lt_cust_order_flg     -- ���g�p���Ȃ�_�ڋq�󒍉\�t���O
       ,ov_transaction_enable   => lt_transaction_enable -- ���g�p���Ȃ�_����\
       ,ov_stock_enabled_flg    => lt_stock_enabled_flg  -- ���g�p���Ȃ�_�݌ɕۗL�\�t���O
       ,ov_return_enable        => lt_return_enable      -- ���g�p���Ȃ�_�ԕi�\
       ,ov_sales_class          => lt_sales_class        -- ���g�p���Ȃ�_����Ώۋ敪
       ,ov_primary_unit         => lt_primary_unit       -- ���g�p���Ȃ�_��P��
       ,on_inventory_item_id    => lt_child_item_id      -- �q�i��ID
       ,ov_primary_uom_code     => lt_primary_uom_code   -- ��P�ʃR�[�h
      );
      -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
      IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_err_msg_xxcoi1_10482
                         ,iv_token_name1  => cv_msg_tkn_org_code_tok
                         ,iv_token_value1 => lt_org_code
                         ,iv_token_name2  => cv_msg_tkn_item_code
                         ,iv_token_value2 => lt_child_item_code
                         ,iv_token_name3  => cv_msg_tkn_err_msg
                         ,iv_token_value3 => lv_errmsg
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END IF;
--
      -- ��P�ʐ��ʂ��擾
      -- �̔����ʊ֐��u�P�ʊ��Z�擾�v
      xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code    => lt_primary_uom_code -- ���Z�O�P�ʃR�[�h
       ,in_before_quantity    => lt_summary_qty      -- ���Z�O����
       ,iov_item_code         => lt_child_item_code  -- �i�ڃR�[�h
       ,iov_organization_code => lt_org_code         -- �݌ɑg�D�R�[�h
       ,ion_inventory_item_id => lt_child_item_id    -- �i�ڂh�c
       ,ion_organization_id   => lt_org_id           -- �݌ɑg�D�h�c
       ,iov_after_uom_code    => lt_primary_uom_code -- ���Z��P�ʃR�[�h
       ,on_after_quantity     => lt_after_quantity   -- ���Z�㐔��
       ,on_content            => ln_content          -- ����
       ,ov_errbuf             => lv_errbuf           -- �G���[�E���b�Z�[�W�G���[
       ,ov_retcode            => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg             => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_err_msg_xxcoi1_10483
                         ,iv_token_name1  => cv_msg_tkn_org_code_tok
                         ,iv_token_value1 => lt_org_code
                         ,iv_token_name2  => cv_msg_tkn_item_code
                         ,iv_token_value2 => lt_child_item_code
                         ,iv_token_name3  => cv_msg_tkn_uom_code
                         ,iv_token_value3 => lt_primary_uom_code
                         ,iv_token_name4  => cv_msg_tkn_err_msg
                         ,iv_token_value4 => lv_errmsg
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- �]�ƈ����̎擾
    BEGIN
      SELECT papf.employee_number                                     emp_code -- �]�ƈ��R�[�h
            ,papf.per_information18 || ' ' || papf.per_information19  emp_name -- �]�ƈ���
      INTO   lt_fix_user_code                                                  -- �m��҃R�[�h
            ,lt_fix_user_name                                                  -- �m��Җ�
      FROM   fnd_user fu                                                       -- ���[�U�}�X�^
            ,per_all_people_f papf                                             -- �]�ƈ��}�X�^
      WHERE  fu.user_id     = cn_created_by                                    -- ���[�UID
      AND    fu.employee_id = papf.person_id
      AND    ld_proc_date BETWEEN papf.effective_start_date
                          AND     papf.effective_end_date                      -- �L�����t�`�F�b�N
      ;
--
    EXCEPTION
      -- �擾�ł��Ȃ������ꍇ�́A�G���[
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_err_msg_xxcoi1_10484
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �V�[�P���X�l�擾
    SELECT xxcoi_lot_transactions_s01.NEXTVAL
    INTO   lt_trx_id
    FROM   DUAL
    ;
--
    -- ���b�g�ʎ�����׍쐬
    INSERT INTO xxcoi_lot_transactions(
      transaction_id                                       -- ���ID
     ,transaction_set_id                                   -- ����Z�b�gID
     ,organization_id                                      -- �݌ɑg�DID
     ,parent_item_id                                       -- �e�i��ID
     ,child_item_id                                        -- �q�i��ID
     ,lot                                                  -- ���b�g
     ,difference_summary_code                              -- �ŗL�L��
     ,transaction_type_code                                -- ����^�C�v�R�[�h
     ,transaction_month                                    -- ����N��
     ,transaction_date                                     -- �����
     ,slip_num                                             -- �`�[No
     ,case_in_qty                                          -- ����
     ,case_qty                                             -- �P�[�X��
     ,singly_qty                                           -- �o����
     ,summary_qty                                          -- �������
     ,transaction_uom                                      -- ��P��
     ,primary_quantity                                     -- ��P�ʐ���
     ,base_code                                            -- ���_�R�[�h
     ,subinventory_code                                    -- �ۊǏꏊ�R�[�h
     ,location_code                                        -- ���P�[�V�����R�[�h
     ,transfer_organization_id                             -- �]����݌ɑg�DID
     ,transfer_subinventory                                -- �]����ۊǏꏊ�R�[�h
     ,transfer_location_code                               -- �]���惍�P�[�V�����R�[�h
     ,source_code                                          -- �\�[�X�R�[�h
     ,relation_key                                         -- �R�t���L�[
     ,reserve_transaction_type_code                        -- ����������^�C�v�R�[�h
     ,reason                                               -- ���R
     ,fix_user_code                                        -- �m��҃R�[�h
     ,fix_user_name                                        -- �m��Җ�
     ,created_by                                           -- �쐬��
     ,creation_date                                        -- �쐬��
     ,last_updated_by                                      -- �ŏI�X�V��
     ,last_update_date                                     -- �ŏI�X�V��
     ,last_update_login                                    -- �ŏI�X�V���O�C��
     ,request_id                                           -- �v��ID
     ,program_application_id                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,program_id                                           -- �R���J�����g�E�v���O����ID
     ,program_update_date                                  -- �v���O�����X�V��
    )VALUES(
      lt_trx_id                                            -- ���ID
     ,lt_trx_set_id                                        -- ����Z�b�gID
     ,lt_org_id                                            -- �݌ɑg�DID
     ,lt_parent_item_id                                    -- �e�i��ID
     ,lt_child_item_id                                     -- �q�i��ID
     ,lt_lot                                               -- ���b�g
     ,lt_diff_sum_code                                     -- �ŗL�L��
     ,lt_trx_type_code                                     -- ����^�C�v�R�[�h
     ,TO_CHAR( lt_trx_date, 'YYYYMM' )                     -- ����N��
     ,lt_trx_date                                          -- �����
     ,lt_slip_num                                          -- �`�[No
     ,lt_case_in_qty                                       -- ����
     ,lt_case_qty                                          -- �P�[�X��
     ,lt_singly_qty                                        -- �o����
     ,lt_summary_qty                                       -- �������
     ,lt_primary_uom_code                                  -- ��P��
     ,lt_after_quantity                                    -- ��P�ʐ���
     ,lt_base_code                                         -- ���_�R�[�h
     ,lt_subinv_code                                       -- �ۊǏꏊ�R�[�h
     ,lt_loc_code                                          -- ���P�[�V�����R�[�h
     ,DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id ) -- �]����݌ɑg�DID
     ,lt_tran_subinv_code                                  -- �]����ۊǏꏊ�R�[�h
     ,lt_tran_loc_code                                     -- �]���惍�P�[�V�����R�[�h
     ,lt_source_code                                       -- �\�[�X�R�[�h
     ,lt_relation_key                                      -- �R�t���L�[
     ,lt_reserve_trx_type_code                             -- ����������^�C�v�R�[�h
     ,lt_reason                                            -- ���R
     ,lt_fix_user_code                                     -- �m��҃R�[�h
     ,lt_fix_user_name                                     -- �m��Җ�
     ,cn_created_by                                        -- �쐬��
     ,cd_creation_date                                     -- �쐬��
     ,cn_last_updated_by                                   -- �ŏI�X�V��
     ,cd_last_update_date                                  -- �ŏI�X�V��
     ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
     ,cn_request_id                                        -- �v��ID
     ,cn_program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,cn_program_id                                        -- �R���J�����g�E�v���O����ID
     ,cd_program_update_date                               -- �v���O�����X�V��
    );
--
    -- OUT�p�����[�^�ݒ�
    on_trx_id := lt_trx_id;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END cre_lot_trx;
--
/************************************************************************
 * Function Name   : GET_CUSTOMER_ID
 * Description     : �ڋq���o�i�󒍃A�h�I���j
 ************************************************************************/
--
  FUNCTION get_customer_id(
    in_deliver_to_id IN NUMBER -- �o�א�ID
  ) RETURN NUMBER 
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ct_status_a           CONSTANT hz_cust_accounts.status%TYPE              := 'A';  -- �ڋq�X�e�[�^�X_�L��
    ct_cust_class_code_10 CONSTANT hz_cust_accounts.customer_class_code%TYPE := '10'; -- �ڋq�敪_�ڋq
--
    -- *** ���[�J���ϐ� ***
    lt_cust_acct_id  hz_cust_accounts.cust_account_id%TYPE; -- �ڋqID(�o�͒l)
    lt_party_site_id hz_party_sites.party_site_id%TYPE;     -- �p�[�e�B�T�C�gID�i���͒l�j
--
  BEGIN
--
    -- ===============================
    -- 1.��������
    -- ===============================
    -- �ϐ�������
    lt_cust_acct_id  := NULL;
    lt_party_site_id := NULL;
--
    -- NULL�̏ꍇ�́A�㑱���������{���Ȃ�
    IF ( in_deliver_to_id IS NULL ) THEN 
      NULL;
    ELSE
      -- IN�p�����[�^�ޔ�
      lt_party_site_id := in_deliver_to_id; -- �p�[�e�B�T�C�gID
--
      -- ===============================
      -- 2.�ڋqID�擾
      -- ===============================
      BEGIN
        SELECT hca.cust_account_id cust_account_id             -- �ڋqID
        INTO   lt_cust_acct_id
        FROM   hz_cust_accounts hca                            -- �ڋq�}�X�^
              ,hz_parties       hp                             -- �p�[�e�B�}�X�^
              ,hz_party_sites   hps                            -- �p�[�e�B�T�C�g�}�X�^
        WHERE  hps.party_site_id       = lt_party_site_id      -- �p�[�e�B�T�C�gID
        AND    hps.party_id            = hp.party_id
        AND    hp.party_id             = hca.party_id
        AND    hca.status              = ct_status_a           -- �X�e�[�^�X
        AND    hca.customer_class_code = ct_cust_class_code_10 -- �ڋq�敪
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
--
    -- ===============================
    -- 3.�߂�l�ݒ�
    -- ===============================
    RETURN lt_cust_acct_id;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_customer_id;
--
/************************************************************************
 * Procedure Name  : GET_PARENT_CHILD_ITEM_INFO
 * Description     : �i�ڃR�[�h���o�i�e�^�q�j
 ************************************************************************/
  PROCEDURE get_parent_child_item_info(
    id_date           IN  DATE            -- ���t
   ,in_inv_org_id     IN  NUMBER          -- �݌ɑg�DID
   ,in_parent_item_id IN  NUMBER          -- �e�i��ID
   ,in_child_item_id  IN  NUMBER          -- �q�i��ID
   ,ot_item_info_tab  OUT item_info_ttype -- �i�ڏ��i�e�[�u���^�j
   ,ov_errbuf         OUT VARCHAR2        -- �G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2        -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg         OUT VARCHAR2        -- ���[�U�[�E�G���[���b�Z�[�W
  )IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_parent_child_item_info'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�W�p�萔
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- �A�v���P�[�V�����Z�k��
    cv_err_msg_xxcoi1_10492   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10492'; -- �i�ځi�e�^�q�j���̓p�����[�^�G���[
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00024'; -- ���̓p�����[�^���ݒ�G���[
    cv_err_msg_xxcoi1_00032   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00032'; -- �v���t�@�C���擾�G���[
    cv_err_msg_xxcoi1_10513   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10513'; -- ���t
    cv_err_msg_xxcoi1_10514   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10514'; -- �݌ɑg�DID
    cv_err_msg_xxcoi1_10520   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10520'; -- �i�ځi�e�^�q�j�擾�G���[
    cv_msg_tkn_param1         CONSTANT VARCHAR2(20)  := 'PARAM1';           -- �g�[�N���F�p�����[�^�P
    cv_msg_tkn_param2         CONSTANT VARCHAR2(20)  := 'PARAM2';           -- �g�[�N���F�p�����[�^�Q
    cv_msg_tkn_item_id        CONSTANT VARCHAR2(20)  := 'ITEM_ID';          -- �g�[�N���F�i��ID
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(20)  := 'IN_PARAM_NAME';    -- �g�[�N���F���̓p�����[�^
    cv_msg_tkn_pro_tok        CONSTANT VARCHAR2(30)  := 'PRO_TOK';          -- �g�[�N���F�v���t�@�C��
    cv_item_div_h             CONSTANT VARCHAR2(30)  := 'XXCOS1_ITEM_DIV_H';-- �v���t�@�C�����FXXCOS:�{�Џ��i�敪
--
    -- *** ���[�J���ϐ� ***
    lv_cstegory_set_name      VARCHAR2(100);   -- �J�e�S���Z�b�g��
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ======================================
    -- �P�F��������
    -- ======================================
    -- �݌ɑg�DID��NULL�̏ꍇ
    IF ( in_inv_org_id IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10514 -- �݌ɑg�DID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���t��NULL�̏ꍇ
    IF ( id_date IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10513 -- ���t
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �e�i��ID�A�q�i��ID���ǂ����NULL�A�܂��͂ǂ����NOT NULL�̏ꍇ�̓G���[
    IF ((in_parent_item_id IS NULL 
      AND  in_child_item_id IS NULL)
    OR (in_parent_item_id IS NOT NULL
       AND  in_child_item_id IS NOT NULL))
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_10492
                    ,iv_token_name1  => cv_msg_tkn_param1
                    ,iv_token_value1 => in_parent_item_id -- �e�i��ID
                    ,iv_token_name2  => cv_msg_tkn_param2
                    ,iv_token_value2 => in_child_item_id  -- �q�i��ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �v���t�@�C���u�{�Џ��i�敪�v�擾
    lv_cstegory_set_name := FND_PROFILE.VALUE( cv_item_div_h );
    IF ( lv_cstegory_set_name IS NULL ) THEN
      -- �G���[���b�Z�[�W
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00032
                     ,iv_token_name1  => cv_msg_tkn_pro_tok
                     ,iv_token_value1 => cv_item_div_h
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- �Q�F�q�i�ڏ��擾
    -- ======================================
    -- IN�p�����[�^.�e�i��ID��NOT NULL�̏ꍇ�A�q�i�ڏ����擾
    IF ( in_parent_item_id IS NOT NULL ) THEN
      SELECT msib2.inventory_item_id item_id         -- �i��ID
            ,iimb2.item_no           item_no         -- �i�ڃR�[�h
            ,ximb2.item_short_name   item_short_name -- ����
            ,item_kbn.item_kbn       item_kbn        -- ���i�敪
            ,item_kbn.item_kbn_name  item_kbn_name   -- ���i�敪��
      BULK COLLECT INTO  ot_item_info_tab           -- �i�ڏ��i�e�[�u���^�j
      FROM   mtl_system_items_b msib1  -- Disc�i�ڃ}�X�^�i�e�j
            ,mtl_system_items_b msib2  -- Disc�i�ڃ}�X�^�i�q�j
            ,ic_item_mst_b      iimb1 -- OPM�i�ڃ}�X�^�i�e�j
            ,ic_item_mst_b      iimb2 -- OPM�i�ڃ}�X�^�i�q�j
            ,xxcmn_item_mst_b   ximb1 -- OPM�i�ڃA�h�I���}�X�^�i�e�j
            ,xxcmn_item_mst_b   ximb2 -- OPM�i�ڃA�h�I���}�X�^�i�q�j
            ,(SELECT gic.item_id        item_id       -- �i��ID
                    ,mcv.segment1       item_kbn      -- ���i�敪
                    ,mcv.description    item_kbn_name -- ���i�敪��
              FROM   gmi_item_categories  gic  -- �i�ڃJ�e�S��
                    ,mtl_category_sets_vl mcsv -- �i�ڃJ�e�S���Z�b�g�r���[
                    ,mtl_categories_vl    mcv  -- �i�ڃJ�e�S���r���[
              WHERE  gic.category_set_id     = mcsv.category_set_id -- �J�e�S���Z�b�gID
                AND  mcsv.category_set_name  = lv_cstegory_set_name -- �J�e�S���Z�b�g��
                AND  gic.category_id         = mcv.category_id      -- �J�e�S��ID
              ) item_kbn
      WHERE msib1.organization_id   = in_inv_org_id
        AND msib1.inventory_item_id = in_parent_item_id
        AND msib1.segment1          = iimb1.item_no
        AND iimb1.item_id           = ximb1.item_id
        AND id_date BETWEEN ximb1.start_date_active AND ximb1.end_date_active
        AND iimb1.item_id           = ximb2.parent_item_id
        AND ximb2.item_id           = iimb2.item_id
        AND id_date BETWEEN ximb2.start_date_active AND ximb2.end_date_active
        AND iimb2.item_no           = msib2.segment1
        AND iimb2.item_id           = item_kbn.item_id
        AND msib2.organization_id   = in_inv_org_id
      ;
--
    ELSIF ( in_child_item_id IS NOT NULL ) THEN
      -- ======================================
      -- �R�F�e�i�ڏ��擾
      -- ======================================
      SELECT msib1.inventory_item_id item_id         -- �i��ID
            ,iimb1.item_no           item_no         -- �i�ڃR�[�h
            ,ximb1.item_short_name   item_short_name -- ����
            ,item_kbn.item_kbn             item_kbn        -- ���i�敪
            ,item_kbn.item_kbn_name        item_kbn_name   -- ���i�敪��
      BULK COLLECT INTO  ot_item_info_tab           -- �i�ڏ��i�e�[�u���^�j
      FROM   mtl_system_items_b msib1  -- Disc�i�ڃ}�X�^�i�e�j
            ,mtl_system_items_b msib2  -- Disc�i�ڃ}�X�^�i�q�j
            ,ic_item_mst_b      iimb1  -- OPM�i�ڃ}�X�^�i�e�j
            ,ic_item_mst_b      iimb2  -- OPM�i�ڃ}�X�^�i�q�j
            ,xxcmn_item_mst_b   ximb1  -- OPM�i�ڃA�h�I���}�X�^�i�e�j
            ,xxcmn_item_mst_b   ximb2  -- OPM�i�ڃA�h�I���}�X�^�i�q�j
            ,(SELECT gic.item_id        item_id       -- �i��ID
                    ,mcv.segment1       item_kbn      -- ���i�敪
                    ,mcv.description    item_kbn_name -- ���i�敪��
              FROM   gmi_item_categories  gic  -- �i�ڃJ�e�S��
                    ,mtl_category_sets_vl mcsv -- �i�ڃJ�e�S���Z�b�g�r���[
                    ,mtl_categories_vl    mcv  -- �i�ڃJ�e�S���r���[
              WHERE  gic.category_set_id     = mcsv.category_set_id -- �J�e�S���Z�b�gID
                AND  mcsv.category_set_name  = lv_cstegory_set_name -- �J�e�S���Z�b�g��
                AND  gic.category_id         = mcv.category_id      -- �J�e�S��ID
              ) item_kbn
      WHERE msib2.organization_id   = in_inv_org_id
        AND msib2.inventory_item_id = in_child_item_id
        AND msib2.segment1          = iimb2.item_no
        AND iimb2.item_id           = ximb2.item_id
        AND id_date BETWEEN ximb2.start_date_active AND ximb2.end_date_active
        AND ximb2.parent_item_id    = ximb1.item_id
        AND ximb1.item_id           = iimb1.item_id
        AND id_date BETWEEN ximb1.start_date_active AND ximb1.end_date_active
        AND iimb1.item_no           = msib1.segment1
        AND iimb1.item_id           = item_kbn.item_id
        AND msib1.organization_id   = in_inv_org_id
      ;
    END IF;
--
    -- �f�[�^���擾�ł��Ȃ������ꍇ
    IF ( ot_item_info_tab.COUNT = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_10520
                    ,iv_token_name1  => cv_msg_tkn_item_id
                    ,iv_token_value1 => NVL(in_parent_item_id,in_child_item_id) -- �i��ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ot_item_info_tab(1).item_id := -1; -- OAF����̋N���ŃG���[�ƂȂ��Ă��܂�����
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ot_item_info_tab(1).item_id := -1; -- OAF����̋N���ŃG���[�ƂȂ��Ă��܂�����
--
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_parent_child_item_info;
--
/************************************************************************
 * Procedure Name  : INS_UPD_LOT_HOLD_INFO
 * Description     : ���b�g���ێ��}�X�^���f
 ************************************************************************/
  PROCEDURE ins_upd_lot_hold_info(
    in_customer_id    IN  NUMBER   -- �ڋqID
   ,in_deliver_to_id  IN  NUMBER   -- �o�א�ID
   ,in_parent_item_id IN  NUMBER   -- �e�i��ID
   ,iv_deliver_lot    IN  VARCHAR2 -- �[�i���b�g
   ,id_delivery_date  IN  DATE     -- �[�i��
   ,iv_e_s_kbn        IN  VARCHAR2 -- �c�Ɛ��Y�敪
   ,iv_cancel_kbn     IN  VARCHAR2 -- ����敪
   ,ov_errbuf         OUT VARCHAR2 -- �G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2 -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg         OUT VARCHAR2 -- ���[�U�[�E�G���[���b�Z�[�W
  )IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'ins_upd_lot_hold_info'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�W�p�萔
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- �A�v���P�[�V�����Z�k��
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00024'; -- ���̓p�����[�^���ݒ�G���[
    cv_err_msg_xxcoi1_10512   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10512'; -- �c�Ɛ��Y�敪�G���[
    cv_err_msg_xxcoi1_10515   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10515'; -- �ڋqID
    cv_err_msg_xxcoi1_10516   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10516'; -- �e�i��ID
    cv_err_msg_xxcoi1_10517   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10517'; -- �[�i���b�g
    cv_err_msg_xxcoi1_10518   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10518'; -- �[�i��
    cv_err_msg_xxcoi1_10519   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10519'; -- �c�Ɛ��Y�敪
    cv_err_msg_xxcoi1_10639   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10639'; -- ����敪�G���[
    cv_err_msg_xxcoi1_10640   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10640'; -- ����敪
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(20)  := 'IN_PARAM_NAME';    -- �g�[�N���F���̓p�����[�^
    cv_e_s_kbn_1              CONSTANT VARCHAR2(20)  := '1';                -- �c�Ɛ��Y�敪�F'1'�i�c�Ɓj
    cv_e_s_kbn_2              CONSTANT VARCHAR2(20)  := '2';                -- �c�Ɛ��Y�敪�F'2'�i���Y�j
    cv_insert_flag_y          CONSTANT VARCHAR2(20)  := 'Y';                -- insert�t���O�F'Y'
    cv_insert_flag_n          CONSTANT VARCHAR2(20)  := 'N';                -- insert�t���O�F'N'
    cv_cancel_kbn_0           CONSTANT VARCHAR2(1)   := '0';                -- ����敪�F'0'
    cv_cancel_kbn_1           CONSTANT VARCHAR2(1)   := '1';                -- ����敪�F'1'
    cv_yyyymmdd               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';       -- ���t�`���FYYYY/MM/DD
    ct_req_status_03          CONSTANT xxwsh_order_headers_all.req_status%TYPE := '03'; 
                                                                            -- �X�e�[�^�X�F03(���ߍς�)
    ct_req_status_04          CONSTANT xxwsh_order_headers_all.req_status%TYPE := '04';
                                                                            -- �X�e�[�^�X�F04(�o�׎��ьv���)
    ct_lastest_ext_flag_y     CONSTANT xxwsh_order_headers_all.latest_external_flag%TYPE := 'Y'; 
                                                                            -- �ŐV�t���O�FY
    ct_lastest_ext_flag_n     CONSTANT xxwsh_order_headers_all.latest_external_flag%TYPE := 'N';
                                                                            -- �ŐV�t���O�FN
    ct_ship_shikyu_class_1    CONSTANT xxwsh_oe_transaction_types2_v.shipping_shikyu_class%TYPE := '1';
                                                                            -- �o�׎x���敪�F1(�o�׈˗�)
    ct_del_flag_y             CONSTANT xxwsh_order_lines_all.delete_flag%TYPE := 'Y'; 
                                                                            -- �폜�t���O�FY
    ct_del_flag_n             CONSTANT xxwsh_order_lines_all.delete_flag%TYPE := 'N'; 
                                                                            -- �폜�t���O�FN
    ct_document_type_10       CONSTANT xxinv_mov_lot_details.document_type_code%TYPE := '10'; 
                                                                            -- �����^�C�v�F10(�o�׈˗�)
    ct_record_type_01         CONSTANT xxinv_mov_lot_details.record_type_code%TYPE := '10'; 
                                                                            -- ���R�[�h�^�C�v�F10(�w��)
    ct_record_type_02         CONSTANT xxinv_mov_lot_details.record_type_code%TYPE := '20'; 
                                                                            -- ���R�[�h�^�C�v�F20(����)
--
--
    -- *** ���[�J���ϐ� ***
    lt_last_deliver_lot_e   xxcoi_mst_lot_hold_info.last_deliver_lot_e%TYPE; -- �[�i���b�g�i�c�Ɓj
    lt_last_deliver_lot_s   xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE; -- �[�i���b�g�i���Y�j
    lt_delivery_date_e      xxcoi_mst_lot_hold_info.delivery_date_e%TYPE;    -- �[�i���i�c�Ɓj
    lt_delivery_date_s      xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;    -- �[�i���i���Y�j
    lt_request_id           xxcoi_mst_lot_hold_info.request_id%TYPE;         -- �v��ID
    lt_lot_hold_info_id     xxcoi_mst_lot_hold_info.lot_hold_info_id%TYPE;   -- ���b�g���ێ��}�X�^ID
    lv_insert_flag          VARCHAR2(1);                                     -- INSERT�t���O
    lt_last_date_03         xxwsh_order_headers_all.arrival_date%TYPE;       -- ���߉ߋ��̏o�׎w����񒅓�
    lt_last_date_04         xxwsh_order_headers_all.arrival_date%TYPE;       -- ���߉ߋ��̏o�׎��я�񒅓�
    ld_last_lot_date        DATE;                                            -- �[�i���b�g���t�^
    lt_upd_lot_s            xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE; -- �[�i���b�g(���Y)�X�V�p
    lt_upd_date_s           xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;    -- �[�i��(���Y)�X�V�p
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    lt_last_deliver_lot_e := NULL;
    lt_last_deliver_lot_s := NULL;
    lt_delivery_date_e    := NULL;
    lt_delivery_date_s    := NULL;
    lt_request_id         := NULL;
    lt_lot_hold_info_id   := NULL;
    lv_insert_flag        := cv_insert_flag_n;
    lt_last_date_03       := NULL;
    lt_last_date_04       := NULL;
    ld_last_lot_date      := NULL;
    lt_upd_lot_s          := NULL;
    lt_upd_date_s         := NULL;
--
    -- ======================================
    -- �P�F��������
    -- ======================================
    -- ���̓p�����[�^�u�ڋqID�v��NULL�̏ꍇ
    IF ( in_customer_id IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_00024
                    ,iv_token_name1  => cv_msg_tkn_in_param_name
                    ,iv_token_value1 => cv_err_msg_xxcoi1_10515 -- �ڋqID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�e�i��ID�v��NULL�̏ꍇ
    IF ( in_parent_item_id IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10516 -- �e�i��ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�c�Ɛ��Y�敪�v��NULL�̏ꍇ
    IF ( iv_e_s_kbn IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10519 -- �c�Ɛ��Y�敪
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    IF ( iv_cancel_kbn IS NULL ) THEN
    -- ���̓p�����[�^�u����敪�v��NULL�̏ꍇ
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10640 -- ����敪
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- IN�p�����[�^.�c�Ɛ��Y�敪��'1'�i�c�Ɓj�܂���'2'�i���Y�j�ȊO�̏ꍇ�̓G���[
    IF ( iv_e_s_kbn <> cv_e_s_kbn_1
      AND iv_e_s_kbn <> cv_e_s_kbn_2
    ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_10512
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- IN�p�����[�^.����敪��0�܂���1�ȊO�̏ꍇ�A�G���[
    IF ( iv_cancel_kbn <> cv_cancel_kbn_0
      AND iv_cancel_kbn <> cv_cancel_kbn_1
    ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_10639
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���Y�̎���ȊO�̏ꍇ�A�K�{
    IF ( iv_e_s_kbn = cv_e_s_kbn_2 AND iv_cancel_kbn = cv_cancel_kbn_1 ) THEN
      NULL;
--
    ELSE
--
      -- ���̓p�����[�^�u�[�i���b�g�v��NULL�̏ꍇ
      IF ( iv_deliver_lot IS NULL ) THEN
        -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_00024
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10517 -- �[�i���b�g
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
  --
      -- ���̓p�����[�^�u�[�i���v��NULL�̏ꍇ
      IF ( id_delivery_date IS NULL ) THEN
        -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_00024
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10518 -- �[�i��
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ======================================
    -- �Q�F���b�g���ێ��}�X�^�擾
    -- ======================================
    -- ����ȊO�̏ꍇ
    IF ( iv_cancel_kbn = cv_cancel_kbn_0 ) THEN
--
      BEGIN
        -- IN�p�����[�^���A���b�g���ێ��}�X�^�̃f�[�^���擾���܂�
        SELECT xmlhi.last_deliver_lot_e  last_deliver_lot_e -- �[�i���b�g�i�c�Ɓj
              ,xmlhi.delivery_date_e     delivery_date_e    -- �[�i���i�c�Ɓj
              ,xmlhi.last_deliver_lot_s  last_deliver_lot_s -- �[�i���b�g�i���Y�j
              ,xmlhi.delivery_date_s     delivery_date_s    -- �[�i���i���Y�j
        INTO   lt_last_deliver_lot_e
              ,lt_delivery_date_e   
              ,lt_last_deliver_lot_s
              ,lt_delivery_date_s   
        FROM   xxcoi_mst_lot_hold_info  xmlhi               -- ���b�g���ێ��}�X�^
        WHERE  xmlhi.customer_id     = in_customer_id       -- �ڋqID
          AND  xmlhi.parent_item_id  = in_parent_item_id    -- �e�i��ID
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- �f�[�^���擾�ł��Ȃ������ꍇ�AINSERT�t���O��Y�ɍX�V���܂�
        lv_insert_flag := cv_insert_flag_y;
      END;
--
    END IF;
--
    -- ======================================
    -- �R�F���b�g���ێ��}�X�^�o�^
    -- ======================================
    -- INSERT�t���O��Y�̏ꍇ�̂ݓo�^���܂�
    IF ( lv_insert_flag = cv_insert_flag_y ) THEN
--
      -- �V�[�P���X�l�擾
      SELECT xxcoi_mst_lot_hold_info_s01.NEXTVAL
      INTO   lt_lot_hold_info_id
      FROM   DUAL
      ;
--
      -- �c�Ɛ��Y�敪�𔻒肵�A�ϐ��ɒl���Z�b�g���܂�
      -- �c�Ɛ��Y�敪��'1'�i�c�Ɓj�̏ꍇ
      IF ( iv_e_s_kbn = cv_e_s_kbn_1 ) THEN
        -- �[�i���b�g�i�c�Ɓj
        lt_last_deliver_lot_e := iv_deliver_lot;
        -- �[�i���i�c�Ɓj
        lt_delivery_date_e    := id_delivery_date;
        -- �[�i���b�g�i���Y�j
        lt_last_deliver_lot_s := NULL;
        -- �[�i���i���Y�j
        lt_delivery_date_s    := NULL;
--
      -- �c�Ɛ��Y�敪��'2'�i���Y�j�̏ꍇ
      ELSE
        -- �[�i���b�g�i�c�Ɓj
        lt_last_deliver_lot_e := NULL;
        -- �[�i���i�c�Ɓj
        lt_delivery_date_e    := NULL;
        -- �[�i���b�g�i���Y�j
        lt_last_deliver_lot_s := iv_deliver_lot;
        -- �[�i���i���Y�j
        lt_delivery_date_s    := id_delivery_date;
      END IF;
--
      -- ���b�g���ێ��}�X�^�o�^
      INSERT INTO xxcoi_mst_lot_hold_info(
        lot_hold_info_id        -- ���b�g���ێ��}�X�^ID
       ,customer_id             -- �ڋqID
       ,parent_item_id          -- �e�i��ID
       ,last_deliver_lot_e      -- �[�i���b�g_�c��
       ,delivery_date_e         -- �[�i��_�c��
       ,last_deliver_lot_s      -- �[�i���b�g_���Y
       ,delivery_date_s         -- �[�i��_���Y
       ,created_by              -- �쐬��
       ,creation_date           -- �쐬��
       ,last_updated_by         -- �ŏI�X�V��
       ,last_update_date        -- �ŏI�X�V��
       ,last_update_login       -- �ŏI�X�V���O�C��
       ,request_id              -- �v��ID
       ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id              -- �R���J�����g�E�v���O����ID
       ,program_update_date     -- �v���O�����X�V��
      )VALUES(
        lt_lot_hold_info_id        -- ���b�g���ێ��}�X�^ID
       ,in_customer_id             -- �ڋqID
       ,in_parent_item_id          -- �e�i��ID
       ,lt_last_deliver_lot_e      -- �[�i���b�g_�c��
       ,lt_delivery_date_e         -- �[�i��_�c��
       ,lt_last_deliver_lot_s      -- �[�i���b�g_���Y
       ,lt_delivery_date_s         -- �[�i��_���Y
       ,cn_created_by              -- �쐬��
       ,cd_creation_date           -- �쐬��
       ,cn_last_updated_by         -- �ŏI�X�V��
       ,cd_last_update_date        -- �ŏI�X�V��
       ,cn_last_update_login       -- �ŏI�X�V���O�C��
       ,cn_request_id              -- �v��ID
       ,cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id              -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date     -- �v���O�����X�V��
      );
--
    -- ======================================
    -- �S�F���b�g���ێ��}�X�^�X�V
    -- ======================================
    -- INSERT�t���O��N�̏ꍇ�͍X�V
    ELSE
--
      -- �c�Ɛ��Y�敪��'1'(�c��)�̏ꍇ
      IF ( iv_e_s_kbn = cv_e_s_kbn_1 ) THEN
        -- �X�V����
        -- �[�i��_�c�Ƃ�NULL
        IF ( lt_delivery_date_e IS NULL 
        -- �[�i��_�c�� < IN�p�����[�^.�[�i��
          OR lt_delivery_date_e < id_delivery_date
        -- �[�i��_�c�� = IN�p�����[�^.�[�i�����[�i���b�g_�c�Ɓ�IN�p�����[�^.�[�i���b�g
          OR ( ( lt_delivery_date_e = id_delivery_date )
            AND ( TO_DATE( lt_last_deliver_lot_e, cv_yyyymmdd ) < TO_DATE( iv_deliver_lot, cv_yyyymmdd ) )
          )
        ) THEN
--
          -- �X�V�Ώۂ̏ꍇ�AIN�p�����[�^�̒l�Ń��b�g���ێ��}�X�^�X�V
          UPDATE xxcoi_mst_lot_hold_info xmlhi
          SET    xmlhi.last_deliver_lot_e      = iv_deliver_lot            -- �[�i���b�g_�c��
                ,xmlhi.delivery_date_e         = id_delivery_date          -- �[�i��_�c��
                ,xmlhi.last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
                ,xmlhi.last_update_date        = cd_last_update_date       -- �ŏI�X�V��
                ,xmlhi.last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
                ,xmlhi.request_id              = cn_request_id             -- �v��ID
                ,xmlhi.program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,xmlhi.program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
                ,xmlhi.program_update_date     = cd_program_update_date    -- �v���O�����X�V��
          WHERE  xmlhi.customer_id             = in_customer_id            -- �ڋqID
            AND  xmlhi.parent_item_id          = in_parent_item_id         -- �e�i��ID
          ;
        END IF;
--
      -- �c�Ɛ��Y�敪��'2'(���Y)�̏ꍇ
      ELSE
        -- ����ȊO�̏ꍇ
        IF ( iv_cancel_kbn = cv_cancel_kbn_0 ) THEN
          -- �X�V����
          -- �[�i��_���Y��NULL
          IF ( lt_delivery_date_s IS NULL
          -- �[�i��_���Y < IN�p�����[�^.�[�i��
            OR lt_delivery_date_s < id_delivery_date
          -- �[�i��_���Y=IN�p�����[�^.�[�i�����[�i���b�g_���Y��IN�p�����[�^.�[�i���b�g
            OR ( ( lt_delivery_date_s = id_delivery_date )
              AND ( TO_DATE( lt_last_deliver_lot_s, cv_yyyymmdd ) < TO_DATE( iv_deliver_lot, cv_yyyymmdd ) )
            )
          ) THEN
            -- ����ȊO�̏ꍇ�ōX�V�Ώۂ̏ꍇ�AIN�p�����[�^�̒l�Ń��b�g���ێ��}�X�^�X�V
            UPDATE xxcoi_mst_lot_hold_info xmlhi
            SET    xmlhi.last_deliver_lot_s      = iv_deliver_lot            -- �[�i���b�g_���Y
                  ,xmlhi.delivery_date_s         = id_delivery_date          -- �[�i��_���Y
                  ,xmlhi.last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
                  ,xmlhi.last_update_date        = cd_last_update_date       -- �ŏI�X�V��
                  ,xmlhi.last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
                  ,xmlhi.request_id              = cn_request_id             -- �v��ID
                  ,xmlhi.program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                  ,xmlhi.program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
                  ,xmlhi.program_update_date     = cd_program_update_date    -- �v���O�����X�V��
            WHERE  xmlhi.customer_id             = in_customer_id            -- �ڋqID
              AND  xmlhi.parent_item_id          = in_parent_item_id         -- �e�i��ID
            ;
--
          END IF;
--
        -- ����̏ꍇ
        ELSE
--
          BEGIN
            -- ���߉ߋ��̏o�׎w�����擾
            SELECT MAX( xoha.schedule_ship_date ) schedule_ship_date        -- MAX(�o�ח\���)
            INTO   lt_last_date_03
            FROM   xxwsh_order_headers_all       xoha                       -- �󒍃w�b�_
                  ,xxwsh_order_lines_all         xola                       -- �󒍖���
                  ,xxwsh_oe_transaction_types2_v xottv                      -- �󒍃^�C�v
            WHERE  xoha.deliver_to_id              = in_deliver_to_id       -- �o�א�ID
              AND  NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                   = ct_lastest_ext_flag_y  -- �ŐV�t���O
              AND  xoha.schedule_ship_date        <= id_delivery_date       -- �o�ח\����FIN�p�����[�^.�[�i��
              AND  xoha.req_status                 = ct_req_status_03       -- �X�e�[�^�X�F���ߍς�
              AND  xottv.transaction_type_id       = xoha.order_type_id     -- �󒍃^�C�vID
              AND  xottv.shipping_shikyu_class     = ct_ship_shikyu_class_1 -- �o�׈˗�
              AND  xottv.start_date_active        <= TRUNC( SYSDATE )       -- �J�n��
              AND  ( ( xottv.end_date_active      >= TRUNC( SYSDATE ) )
                    OR ( xottv.end_date_active     IS NULL ) 
                   )                                                        -- �I����
              AND  xola.order_header_id            = xoha.order_header_id   -- �󒍃w�b�_ID
              AND  xola.shipping_item_code        IN                        -- �o�וi��
                  ( SELECT ximv.item_no item_no                             -- �i�ڃR�[�h
                    FROM   xxcmn_item_mst2_v  ximv                          -- �i�ڏ��r���[2_�q
                          ,xxcmn_item_mst2_v  ximv2                         -- �i�ڏ��r���[2_�e
                    WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- �K�p�J�n��
                    AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- �K�p�I����
                    AND    ximv.parent_item_id     = ximv2.item_id
                    AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- �K�p�J�n��
                    AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- �K�p�I����
                    AND    ximv2.inventory_item_id  = in_parent_item_id     -- IN�p�����[�^.�e�i��ID
                  )
              AND  NVL( xola.delete_flag,  ct_del_flag_n ) 
                                                  <> ct_del_flag_y          -- �폜�t���O'Y'�ȊO
            ;
          EXCEPTION
            -- ���擾����NULL��ݒ肵�p��
            WHEN NO_DATA_FOUND THEN
              lt_last_date_03 := NULL;
          END;
--
          BEGIN
            -- ���߉ߋ��̏o�׎��я��
            SELECT  MAX( info.arrival_date ) arrival_date                      -- �ő咅�ד�
            INTO    lt_last_date_04
            FROM(
              SELECT xoha.arrival_date arrival_date                            -- ���ד�
              FROM   xxwsh_order_headers_all       xoha                        -- �󒍃w�b�_�A�h�I��
                    ,xxwsh_order_lines_all         xola                        -- �󒍖��׃A�h�I��
                    ,xxwsh_oe_transaction_types2_v xottv                       -- �󒍃^�C�v
              WHERE  xoha.result_deliver_to_id        = in_deliver_to_id       -- �o�א�ID(����)
                AND  NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                      = ct_lastest_ext_flag_y  -- �ŐV�t���O
                AND  xoha.req_status                  = ct_req_status_04       -- �X�e�[�^�X�F�o�׎��ьv���
                AND  xottv.transaction_type_id        = xoha.order_type_id     -- �󒍃^�C�vID
                AND  xottv.shipping_shikyu_class      = ct_ship_shikyu_class_1 -- �o�׎x���敪
                AND  xottv.start_date_active         <= TRUNC( SYSDATE )       -- �J�n��
                AND  ( ( xottv.end_date_active       >= TRUNC( SYSDATE ) )
                       OR ( xottv.end_date_active    IS NULL )
                     )                                                         -- �I����
                AND  xola.order_header_id             = xoha.order_header_id   -- �󒍃w�b�_ID
                AND  xola.shipping_item_code       IN                          -- �o�וi��
                  ( SELECT ximv.item_no item_no                                -- �i�ڃR�[�h
                    FROM   xxcmn_item_mst2_v  ximv                             -- �i�ڏ��r���[2_�q
                          ,xxcmn_item_mst2_v  ximv2                            -- �i�ڏ��r���[2_�e
                    WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )         -- �K�p�J�n��
                    AND    ximv.end_date_active    >= TRUNC( SYSDATE )         -- �K�p�I����
                    AND    ximv.parent_item_id     = ximv2.item_id
                    AND    ximv2.start_date_active <= TRUNC( SYSDATE )         -- �K�p�J�n��
                    AND    ximv2.end_date_active   >= TRUNC( SYSDATE )         -- �K�p�I����
                    AND    ximv2.inventory_item_id  = in_parent_item_id        -- IN�p�����[�^.�e�i��ID
                  )
                AND  NVL( xola.delete_flag, ct_del_flag_n )
                                                    <> ct_del_flag_y           -- �폜�t���O'Y'�ȊO
                AND  xola.shipped_quantity           > 0                       -- �o�׎��ѐ���0�ȏ�
              UNION ALL
              SELECT /*+ leading(xoha) index(xoha xxwsh_oh_n13) */
                     xoha.arrival_date arrival_date                            -- ���ד�
              FROM   xxwsh_order_headers_all       xoha                        -- �󒍃w�b�_�A�h�I��
                    ,xxwsh_order_lines_all         xola                        -- �󒍖��׃A�h�I��
                    ,xxwsh_oe_transaction_types2_v xottv                       -- �󒍃^�C�v
              WHERE  xoha.result_deliver_to_id       IS NULL                   -- �o�א�ID(����)
                AND  xoha.deliver_to_id               = in_deliver_to_id       -- �o�א�ID
                AND  NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                      = ct_lastest_ext_flag_y  -- �ŐV�t���O
                AND  xoha.req_status                  = ct_req_status_04       -- �X�e�[�^�X�F�o�׎��ьv���
                AND  xottv.transaction_type_id        = xoha.order_type_id     -- �󒍃^�C�vID
                AND  xottv.shipping_shikyu_class      = ct_ship_shikyu_class_1 -- �o�׎x���敪
                AND  xottv.start_date_active         <= TRUNC( SYSDATE )       -- �J�n��
                AND  ( ( xottv.end_date_active       >= TRUNC( SYSDATE ) )
                       OR( xottv.end_date_active     IS NULL )
                     )                                                         -- �I����
                AND  xola.order_header_id             = xoha.order_header_id   -- �󒍃w�b�_ID
                AND  xola.shipping_item_code         IN                        -- �o�וi��
                  ( SELECT ximv.item_no item_no                             -- �i�ڃR�[�h
                    FROM   xxcmn_item_mst2_v  ximv                          -- �i�ڏ��r���[2_�q
                          ,xxcmn_item_mst2_v  ximv2                         -- �i�ڏ��r���[2_�e
                    WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- �K�p�J�n��
                    AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- �K�p�I����
                    AND    ximv.parent_item_id     = ximv2.item_id
                    AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- �K�p�J�n��
                    AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- �K�p�I����
                    AND    ximv2.inventory_item_id  = in_parent_item_id     -- IN�p�����[�^.�e�i��ID
                  )
                AND  NVL( xola.delete_flag, ct_del_flag_n )  
                                                     <> ct_del_flag_y           -- �폜�t���O'Y'�ȊO
                AND  xola.shipped_quantity            > 0                       -- �o�׎��ѐ���0�ȏ�
              ) info
            ;
          EXCEPTION
            -- ���擾����NULL���Z�b�g���������p��
            WHEN NO_DATA_FOUND THEN
              lt_last_date_04 := NULL;
          END;
--
          -- �ܖ������擾
          -- �w�����тƂ��ɑ��݂��Ȃ��ꍇ
          IF ( ( lt_last_date_03 IS NULL ) AND ( lt_last_date_04 IS NULL ) ) THEN
            NULL;
          -- ���� < �w�� �̏ꍇ
          ELSIF ( ( lt_last_date_04 < lt_last_date_03 ) OR ( lt_last_date_04 IS NULL ) ) THEN
          --
            -- �ܖ������擾
            SELECT MAX( TO_DATE( ilm.attribute3, cv_yyyymmdd ) ) taste_term   -- �ܖ�����
              INTO ld_last_lot_date
              FROM xxwsh_order_headers_all        xoha                        -- �󒍃w�b�_�A�h�I��
                  ,xxwsh_order_lines_all          xola                        -- �󒍖��׃A�h�I��
                  ,xxinv_mov_lot_details          xmld                        -- �ړ����b�g�ڍ�
                  ,xxwsh_oe_transaction_types2_v  xottv                       -- �󒍃^�C�v
                  ,ic_lots_mst                    ilm                         -- OPM���b�g�}�X�^
             WHERE xoha.deliver_to_id              = in_deliver_to_id         -- �o�א�ID
               AND NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                   = ct_lastest_ext_flag_y    -- �ŐV�t���O
               AND xoha.schedule_ship_date         = TRUNC( lt_last_date_03 ) -- �o�ח\����F�o�׎w�����̍ő咅��
               AND xoha.req_status                 = ct_req_status_03         -- �X�e�[�^�X�F���ߍς�
               AND xottv.transaction_type_id       = xoha.order_type_id       -- �󒍃^�C�vID
               AND xottv.shipping_shikyu_class     = ct_ship_shikyu_class_1   -- �o�׈˗�
               AND xottv.start_date_active        <= TRUNC( SYSDATE )         -- �J�n��
               AND ( ( xottv.end_date_active      >= TRUNC( SYSDATE ) )
                    OR ( xottv.end_date_active    IS NULL ) 
                   )                                                          -- �I����
               AND xola.order_header_id            = xoha.order_header_id     -- �󒍃w�b�_ID
               AND xola.shipping_item_code        IN                          -- �o�וi��
                  ( SELECT ximv.item_no item_no                             -- �i�ڃR�[�h
                    FROM   xxcmn_item_mst2_v  ximv                          -- �i�ڏ��r���[2_�q
                          ,xxcmn_item_mst2_v  ximv2                         -- �i�ڏ��r���[2_�e
                    WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- �K�p�J�n��
                    AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- �K�p�I����
                    AND    ximv.parent_item_id     = ximv2.item_id
                    AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- �K�p�J�n��
                    AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- �K�p�I����
                    AND    ximv2.inventory_item_id  = in_parent_item_id     -- IN�p�����[�^.�e�i��ID
                  )
               AND NVL( xola.delete_flag,  ct_del_flag_n ) 
                                                  <> ct_del_flag_y            -- �폜�t���O'Y'�ȊO
               AND xmld.mov_line_id                = xola.order_line_id       -- ����ID
               AND xmld.document_type_code         = ct_document_type_10      -- �����^�C�v�F�o�׈˗�
               AND xmld.record_type_code           = ct_record_type_01        -- ���R�[�h�^�C�v�F�w��
               AND ilm.lot_id                      = xmld.lot_id              -- OPM���b�gID
               AND ilm.item_id                     = xmld.item_id             -- OPM�i��ID
            ;
--
            -- �o�ד��A�o�׃��b�g�ݒ�
            lt_upd_lot_s  := TO_CHAR( ld_last_lot_date, cv_yyyymmdd ); -- �o�׃��b�g
            lt_upd_date_s := lt_last_date_03;                          -- �o�ד�
--
          -- �w�� < ���� �̏ꍇ
          ELSE
            SELECT MAX( TO_DATE( info.taste_term, cv_yyyymmdd ) ) taste_term
              INTO ld_last_lot_date
              FROM(
                SELECT ilm.attribute3 taste_term                                 -- �ܖ�����
                  FROM xxwsh_order_headers_all        xoha                       -- �󒍃w�b�_�A�h�I��
                      ,xxwsh_order_lines_all          xola                       -- �󒍖��׃A�h�I��
                      ,xxinv_mov_lot_details          xmld                       -- �ړ����b�g�ڍ�
                      ,xxwsh_oe_transaction_types2_v  xottv                      -- �󒍃^�C�v
                      ,ic_lots_mst                    ilm                        -- OPM���b�g�}�X�^
                 WHERE xoha.result_deliver_to_id      = in_deliver_to_id         -- �o�א�ID(����)
                   AND xoha.arrival_date             >= TRUNC( lt_last_date_04 ) -- ���ד�:�o�׎��я��̍ő咅��
                   AND xoha.arrival_date              < TRUNC( lt_last_date_04 + 1 ) -- ���ד�:�o�׎��я��̍ő咅��
                   AND NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n ) 
                                                      = ct_lastest_ext_flag_y    -- �ŐV�t���O=Y
                   AND xoha.req_status                = ct_req_status_04         -- �X�e�[�^�X�F�o�׎��ьv���
                   AND xottv.transaction_type_id      = xoha.order_type_id       -- �󒍃^�C�vID
                   AND xottv.shipping_shikyu_class    = ct_ship_shikyu_class_1   -- �o�׈˗�
                   AND xottv.start_date_active       <= TRUNC( SYSDATE )
                   AND ( ( xottv.end_date_active     >= TRUNC( SYSDATE ) )
                         OR ( xottv.end_date_active  IS NULL ) 
                       )
                   AND xola.order_header_id           = xoha.order_header_id     -- �󒍃w�b�_ID
                   AND xola.shipping_item_code       IN                          -- �o�וi��
                       ( SELECT ximv.item_no item_no                             -- �i�ڃR�[�h
                         FROM   xxcmn_item_mst2_v  ximv                          -- �i�ڏ��r���[2_�q
                               ,xxcmn_item_mst2_v  ximv2                         -- �i�ڏ��r���[2_�e
                         WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- �K�p�J�n��
                         AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- �K�p�I����
                         AND    ximv.parent_item_id     = ximv2.item_id
                         AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- �K�p�J�n��
                         AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- �K�p�I����
                         AND    ximv2.inventory_item_id  = in_parent_item_id     -- IN�p�����[�^.�e�i��ID
                       )
                   AND NVL( xola.delete_flag, ct_del_flag_n ) 
                                                     <> ct_del_flag_y            -- �폜�t���O'Y'�ȊO
                   AND xmld.mov_line_id               = xola.order_line_id       -- ����ID
                   AND xmld.document_type_code        = ct_document_type_10      -- �����^�C�v�F�o�׈˗�
                   AND xmld.record_type_code          = ct_record_type_02        -- ���R�[�h�^�C�v�F�o�׎���
                   AND ilm.lot_id                     = xmld.lot_id              -- OPM���b�gID
                   AND ilm.item_id                    = xmld.item_id             -- OPM�i��ID
                   AND xmld.actual_quantity           > 0                        -- ���ѐ���
                UNION ALL
                SELECT /*+ leading(xoha xola) index(xoha xxwsh_oh_n13) */
                       ilm.attribute3 taste_term                                 -- �ܖ�����
                  FROM xxwsh_order_headers_all        xoha                       -- �󒍃w�b�_�A�h�I��
                      ,xxwsh_order_lines_all          xola                       -- �󒍖��׃A�h�I��
                      ,xxinv_mov_lot_details          xmld                       -- �ړ����b�g�ڍ�
                      ,xxwsh_oe_transaction_types2_v  xottv                      -- �󒍃^�C�v
                      ,ic_lots_mst                    ilm                        -- OPM���b�g�}�X�^
                 WHERE xoha.result_deliver_to_id     IS NULL                     -- �o�א�ID(����)
                   AND xoha.deliver_to_id             = in_deliver_to_id         -- �o�א�ID
                   AND xoha.schedule_arrival_date    >= TRUNC( lt_last_date_04 ) -- ���ח\���:�o�׎��я��̍ő咅��
                   AND xoha.schedule_arrival_date     < TRUNC( lt_last_date_04 + 1 ) -- ���ח\���:�o�׎��я��̍ő咅��
                   AND NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                      = ct_lastest_ext_flag_y    -- �ŐV�t���O=Y
                   AND xoha.req_status                = ct_req_status_04         -- �o�׎��ьv���
                   AND xottv.transaction_type_id      = xoha.order_type_id       -- �󒍃^�C�vID
                   AND xottv.shipping_shikyu_class    = ct_ship_shikyu_class_1   -- �o�׈˗�
                   AND xottv.start_date_active       <= TRUNC( SYSDATE )         -- �J�n��
                   AND ( ( xottv.end_date_active     >= TRUNC( SYSDATE ) )
                         OR( xottv.end_date_active   IS NULL )
                       )                                                         -- �I����
                   AND xola.order_header_id           = xoha.order_header_id     -- �󒍃w�b�_ID
                   AND xola.shipping_item_code       IN                          -- �o�וi��
                       ( SELECT ximv.item_no item_no                             -- �i�ڃR�[�h
                         FROM   xxcmn_item_mst2_v  ximv                          -- �i�ڏ��r���[2_�q
                               ,xxcmn_item_mst2_v  ximv2                         -- �i�ڏ��r���[2_�e
                         WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- �K�p�J�n��
                         AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- �K�p�I����
                         AND    ximv.parent_item_id     = ximv2.item_id
                         AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- �K�p�J�n��
                         AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- �K�p�I����
                         AND    ximv2.inventory_item_id  = in_parent_item_id     -- IN�p�����[�^.�e�i��ID
                       )
                   AND NVL( xola.delete_flag, ct_del_flag_n ) 
                                                     <> ct_del_flag_y            -- �폜�t���O'Y'�ȊO
                   AND xmld.mov_line_id               = xola.order_line_id       -- ����ID
                   AND xmld.document_type_code        = ct_document_type_10      -- �����^�C�v
                   AND xmld.record_type_code          = ct_record_type_02        -- ���R�[�h�^�C�v
                   AND ilm.lot_id                     = xmld.lot_id              -- OPM���b�gID
                   AND ilm.item_id                    = xmld.item_id             -- OPM�i��ID
                   AND xmld.actual_quantity           > 0                        -- ���ѐ���
              ) info
            ;
            -- �o�ד��A�o�׃��b�g�ݒ�
            lt_upd_lot_s  := TO_CHAR( ld_last_lot_date, cv_yyyymmdd ); -- �o�׃��b�g
            lt_upd_date_s := lt_last_date_04;                          -- �o�ד�
--
          END IF;
--
          IF ( lt_upd_lot_s IS NOT NULL ) THEN
            -- ���b�g���ێ��}�X�^�X�V
            UPDATE xxcoi_mst_lot_hold_info xmlhi
            SET    xmlhi.last_deliver_lot_s      = lt_upd_lot_s              -- �[�i���b�g_���Y
                  ,xmlhi.delivery_date_s         = TRUNC( lt_upd_date_s )    -- �[�i��_���Y
                  ,xmlhi.last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
                  ,xmlhi.last_update_date        = cd_last_update_date       -- �ŏI�X�V��
                  ,xmlhi.last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
                  ,xmlhi.request_id              = cn_request_id             -- �v��ID
                  ,xmlhi.program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                  ,xmlhi.program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
                  ,xmlhi.program_update_date     = cd_program_update_date    -- �v���O�����X�V��
            WHERE  xmlhi.customer_id             = in_customer_id            -- �ڋqID
              AND  xmlhi.parent_item_id          = in_parent_item_id         -- �e�i��ID
            ;
          END IF;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- ======================================
    -- �T�F�G���[����
    -- ======================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END ins_upd_lot_hold_info;
--
/************************************************************************
 * Procedure Name  : INS_UPD_DEL_LOT_ONHAND
 * Description     : ���b�g�ʎ莝���ʔ��f
 ************************************************************************/
  PROCEDURE ins_upd_del_lot_onhand(
    in_inv_org_id       IN  NUMBER           -- �݌ɑg�DID
   ,iv_base_code        IN  VARCHAR2         -- ���_�R�[�h
   ,iv_subinv_code      IN  VARCHAR2         -- �ۊǏꏊ�R�[�h
   ,iv_loc_code         IN  VARCHAR2         -- ���P�[�V�����R�[�h
   ,in_child_item_id    IN  NUMBER           -- �q�i��ID
   ,iv_lot              IN  VARCHAR2         -- ���b�g(�ܖ�����)
   ,iv_diff_sum_code    IN  VARCHAR2         -- �ŗL�L��
   ,in_case_in_qty      IN  NUMBER           -- ����
   ,in_case_qty         IN  NUMBER           -- �P�[�X��
   ,in_singly_qty       IN  NUMBER           -- �o����
   ,in_summary_qty      IN  NUMBER           -- �������
   ,ov_errbuf           OUT VARCHAR2         -- �G���[���b�Z�[�W
   ,ov_retcode          OUT VARCHAR2         -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg           OUT VARCHAR2         -- ���[�U�[�E�G���[���b�Z�[�W
  )IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'ins_upd_del_lot_onhand'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�W�p�萔
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- �A�v���P�[�V�����Z�k��
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00024'; -- ���̓p�����[�^���ݒ�G���[
    cv_err_msg_xxcoi1_10500   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10500'; -- ����
    cv_err_msg_xxcoi1_10501   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10501'; -- �������
    cv_err_msg_xxcoi1_10502   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10502'; -- ���_�R�[�h
    cv_err_msg_xxcoi1_10503   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10503'; -- �ۊǏꏊ�R�[�h
    cv_err_msg_xxcoi1_10514   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10514'; -- �݌ɑg�DID
    cv_err_msg_xxcoi1_10581   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10581'; -- ���P�[�V�����R�[�h
    cv_err_msg_xxcoi1_10582   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10582'; -- �q�i��ID
    cv_err_msg_xxcoi1_10583   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10583'; -- ���̓p�����[�^�}�C�i�X�G���[
    cv_err_msg_xxcoi1_10584   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10584'; -- ���̓p�����[�^�i�����j�Ó����G���[
    cv_err_msg_xxcoi1_10585   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10585'; -- �莝���ʎZ�o���ʃ}�C�i�X�G���[
    cv_err_msg_xxcoi1_10586   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10586'; -- �P�[�X��
    cv_err_msg_xxcoi1_10587   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10587'; -- �o����
    cv_err_msg_xxcoi1_10607   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10607'; -- �������擾�G���[
--
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(13)  := 'IN_PARAM_NAME';    -- �g�[�N���F���̓p�����[�^
    cv_msg_tkn_item_id        CONSTANT VARCHAR2(13)  := 'ITEM_ID';          -- �g�[�N���F�i��ID
    cv_msg_tkn_diff_sum_code  CONSTANT VARCHAR2(13)  := 'DIFF_SUM_CODE';    -- �g�[�N���F�ŗL�L��
    cv_msg_tkn_lot            CONSTANT VARCHAR2(13)  := 'LOT';              -- �g�[�N���F���b�g
--
    cv_insert_flag_y          CONSTANT VARCHAR2(1)   := 'Y';                -- insert�t���O�F'Y'
    cv_insert_flag_n          CONSTANT VARCHAR2(1)   := 'N';                -- insert�t���O�F'N'
    cv_lot_no_dafault         CONSTANT VARCHAR2(10)  := 'DEFAULTLOT';       -- ���b�g�ԍ��F'DEFAULTLOT'
--
    cv_date_fmt               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';       -- ���t�^YYYY/MM/DD
--
    -- *** ���[�J���ϐ� ***
    lt_case_qty        xxcoi_lot_onhand_quantites.case_qty%TYPE;    -- �P�[�X��
    lt_singly_qty      xxcoi_lot_onhand_quantites.singly_qty%TYPE;  -- �o����
    lt_summary_qty     xxcoi_lot_onhand_quantites.summary_qty%TYPE; -- �������
    lt_case_qty_sum    xxcoi_lot_onhand_quantites.case_qty%TYPE;    -- �P�[�X���i�Z�o�p�j
    lt_singly_qty_sum  xxcoi_lot_onhand_quantites.singly_qty%TYPE;  -- �o�����i�Z�o�p�j
    lt_summary_qty_sum xxcoi_lot_onhand_quantites.summary_qty%TYPE; -- ������ʁi�Z�o�p�j
    lt_product_date    ic_lots_mst.attribute1%TYPE;                 -- �����N����
    lv_insert_flag     VARCHAR2(1);                                 -- INSERT�t���O
    ln_case_qty_minus  NUMBER;                                      -- �P�[�X���i�������v�Z�p�j
    lt_expiration_day  xxcmn_item_mst_b.expiration_day%TYPE;        -- �ܖ�����
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    lt_case_qty         := NULL;  -- �P�[�X��
    lt_singly_qty       := NULL;  -- �o����
    lt_summary_qty      := NULL;  -- �������
    lt_case_qty_sum     := NULL;  -- �P�[�X���i�Z�o�p�j
    lt_singly_qty_sum   := NULL;  -- �o�����i�Z�o�p�j
    lt_summary_qty_sum  := NULL;  -- ������ʁi�Z�o�p�j
    lt_product_date     := NULL;  -- �����N����
    ln_case_qty_minus   := NULL;  -- �P�[�X���i�������v�Z�p�j
    lv_insert_flag      := cv_insert_flag_n; -- INSERT�t���O
--
    -- ======================================
    -- �P�F��������
    -- ======================================
    -- ���̓p�����[�^�u�݌ɑg�DID�v��NULL�̏ꍇ
    IF ( in_inv_org_id IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10514 -- �݌ɑg�DID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u���_�R�[�h�v��NULL�̏ꍇ
    IF ( iv_base_code IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10502 -- ���_�R�[�h
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�ۊǏꏊ�R�[�h�v��NULL�̏ꍇ
    IF ( iv_subinv_code IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10503 -- �ۊǏꏊ�R�[�h
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u���P�[�V�����R�[�h�v��NULL�̏ꍇ
    IF ( iv_loc_code IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10581 -- ���P�[�V�����R�[�h
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�q�i��ID�v��NULL�̏ꍇ
    IF ( in_child_item_id IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10582 -- �q�i��ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u������ʁv��NULL�̏ꍇ
    IF ( in_summary_qty IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10501 -- �������
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�����v��NULL�̏ꍇ
    IF ( in_case_in_qty IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10500 -- ����
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- -- ���̓p�����[�^�u�����v��0�ȉ��̏ꍇ
    IF ( in_case_in_qty <= 0) THEN
      -- ���̓p�����[�^�i�����j�Ó����G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10584
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- WHO�J�����̎擾
    -- �Œ�O���[�o���ϐ����g�p���邽�ߊ���
--
    -- ======================================
    -- �Q�F���b�g�ʎ莝���ʒ��o
    -- ======================================
    BEGIN
      -- IN�p�����[�^���A���b�g�ʎ莝���ʂ̃f�[�^���擾���܂�
      SELECT xloq.case_qty    case_qty    -- �P�[�X��
            ,xloq.singly_qty  singly_qty  -- �o����
            ,xloq.summary_qty summary_qty -- �������
      INTO   lt_case_qty    -- �P�[�X��
            ,lt_singly_qty  -- �o����
            ,lt_summary_qty -- �������
      FROM   xxcoi_lot_onhand_quantites  xloq  -- ���b�g�ʎ莝����
      WHERE  xloq.organization_id    = in_inv_org_id     -- �݌ɑg�DID
        AND  xloq.base_code          = iv_base_code      -- ���_�R�[�h
        AND  xloq.subinventory_code  = iv_subinv_code    -- �ۊǏꏊ�R�[�h
        AND  xloq.location_code      = iv_loc_code       -- ���P�[�V�����R�[�h
        AND  xloq.child_item_id      = in_child_item_id  -- �q�i��ID
        AND  (xloq.lot               = iv_lot
           OR (xloq.lot IS NULL AND iv_lot IS NULL))     -- ���b�g�i�ܖ������j
        AND  (xloq.difference_summary_code  = iv_diff_sum_code
           OR (xloq.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL)) -- �ŗL�L��
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �f�[�^���擾�ł��Ȃ������ꍇ�AINSERT�t���O��Y�ɍX�V���܂�
      lv_insert_flag := cv_insert_flag_y;
    END;
    -- ======================================
    -- �R�F���b�g�ʎ莝���ʓo�^
    -- ======================================
    -- INSERT�t���O��Y�̏ꍇ�̂ݓo�^���܂�
    IF ( lv_insert_flag = cv_insert_flag_y ) THEN
      -- ���̓p�����[�^�`�F�b�N
      -- ���̓p�����[�^�u�P�[�X���v���}�C�i�X�̏ꍇ
      IF ( in_case_qty < 0 ) THEN
        -- ���̓p�����[�^�}�C�i�X�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10583
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10586 -- �P�[�X��
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- ���̓p�����[�^�u�o�����v���}�C�i�X�̏ꍇ
      IF ( in_singly_qty < 0 ) THEN
        -- ���̓p�����[�^�}�C�i�X�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10583
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10587 -- �o����
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- ���̓p�����[�^�u������ʁv���}�C�i�X�̏ꍇ
      IF ( in_summary_qty < 0 ) THEN
        -- ���̓p�����[�^�}�C�i�X�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10583
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10501 -- �������
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      BEGIN
        -- ���������擾
        -- ���b�g�i�ܖ������j��NULL�̏ꍇ�͐�������NULL��ݒ�
        IF ( iv_lot IS NULL ) THEN
          lt_product_date := NULL;
--
        -- ���b�g�i�ܖ������j��NULL�ȊO�̏ꍇ�͏ܖ�����-�ܖ����ԂŐ������𓱏o
        ELSE
          -- �ܖ����ԓ��o
          SELECT ximb.expiration_day expiration_day        -- �ܖ�����
          INTO   lt_expiration_day
          FROM   xxcmn_item_mst_b   ximb                   -- OPM�i�ڃA�h�I���}�X�^
                ,ic_item_mst_b      iimb                   -- OPM�i�ڃ}�X�^
                ,mtl_system_items_b msib                   -- Disc�i�ڃ}�X�^
          WHERE msib.organization_id    = in_inv_org_id    -- IN�p�����[�^.�݌ɑg�DID
          AND   msib.inventory_item_id  = in_child_item_id -- IN�p�����[�^.Disc�i��ID
          AND   iimb.item_no            = msib.segment1
          AND   iimb.item_id            = ximb.item_id
          AND   ximb.start_date_active <= TRUNC( SYSDATE ) -- �K�p�J�n��
          AND   ximb.end_date_active   >= TRUNC( SYSDATE ) -- �K�p�I����
          ;
--
          -- IN�p�����[�^.�ܖ����� - �Z�o�����ܖ����Ԃ̌v�Z���ʂ𐻑����ɐݒ肷��
          lt_product_date := TO_CHAR( TO_DATE( iv_lot , cv_date_fmt ) - lt_expiration_day , cv_date_fmt );
--
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �������擾�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_err_msg_xxcoi1_10607
                         ,iv_token_name1  => cv_msg_tkn_item_id
                         ,iv_token_value1 => in_child_item_id   -- �q�i��ID
                         ,iv_token_name2  => cv_msg_tkn_diff_sum_code
                         ,iv_token_value2 => iv_diff_sum_code   -- �ŗL�L��
                         ,iv_token_name3  => cv_msg_tkn_lot
                         ,iv_token_value3 => iv_lot             -- ���b�g
                        );
           lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- ������ʂ�0���傫���ꍇ�A�莝���ʂ𔽉f
      IF( NVL( in_summary_qty, 0 ) > 0 )THEN
        -- ���b�g�ʎ莝���ʓo�^
        INSERT INTO xxcoi_lot_onhand_quantites(
          organization_id         -- �݌ɑg�DID
         ,base_code               -- ���_�R�[�h
         ,subinventory_code       -- �ۊǏꏊ�R�[�h
         ,location_code           -- ���P�[�V�����R�[�h
         ,child_item_id           -- �q�i��ID
         ,lot                     -- ���b�g
         ,difference_summary_code -- �ŗL�L��
         ,case_in_qty             -- ����
         ,case_qty                -- �P�[�X��
         ,singly_qty              -- �o����
         ,summary_qty             -- �������
         ,production_date         -- ������
         ,created_by              -- �쐬��
         ,creation_date           -- �쐬��
         ,last_updated_by         -- �ŏI�X�V��
         ,last_update_date        -- �ŏI�X�V��
         ,last_update_login       -- �ŏI�X�V���O�C��
         ,request_id              -- �v��ID
         ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id              -- �R���J�����g�E�v���O����ID
         ,program_update_date     -- �v���O�����X�V��
        )VALUES(
          in_inv_org_id             -- �݌ɑg�DID
         ,iv_base_code              -- ���_�R�[�h
         ,iv_subinv_code            -- �ۊǏꏊ�R�[�h
         ,iv_loc_code               -- ���P�[�V�����R�[�h
         ,in_child_item_id          -- �q�i��ID
         ,iv_lot                    -- ���b�g
         ,iv_diff_sum_code          -- �ŗL�L��
         ,in_case_in_qty            -- ����
         ,NVL( in_case_qty, 0 )     -- �P�[�X��
         ,NVL( in_singly_qty, 0 )   -- �o����
         ,NVL( in_summary_qty, 0 )  -- �������
         ,lt_product_date           -- ������
         ,cn_created_by             -- �쐬��
         ,cd_creation_date          -- �쐬��
         ,cn_last_updated_by        -- �ŏI�X�V��
         ,cd_last_update_date       -- �ŏI�X�V��
         ,cn_last_update_login      -- �ŏI�X�V���O�C��
         ,cn_request_id             -- �v��ID
         ,cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id             -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date    -- �v���O�����X�V��
        );
      END IF;
--
    -- ======================================
    -- �S�F���b�g���ێ��}�X�^�X�V
    -- ======================================
    ELSE
      -- �P�[�X���A�o�����A������ʂ̎Z�o
      -- �P�[�X��
      lt_case_qty_sum     := NVL(lt_case_qty,0) + NVL(in_case_qty,0);
      -- �o����
      lt_singly_qty_sum   := NVL(lt_singly_qty,0) + NVL(in_singly_qty,0);
      -- �������
      lt_summary_qty_sum  := NVL(lt_summary_qty,0) + NVL(in_summary_qty,0);
--
      -- �P�[�X�����}�C�i�X�̏ꍇ�̓G���[
      IF ( lt_case_qty_sum  < 0 ) THEN
        -- �莝���ʎZ�o���ʃ}�C�i�X�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10585
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- �o�������}�C�i�X�̏ꍇ�A�P�[�X��������
      IF ( lt_singly_qty_sum < 0 ) THEN
        -- �������P�[�X�����Z�o
        IF ( MOD(lt_singly_qty_sum,in_case_in_qty) = 0 ) THEN
          -- �o�����������̔{���̏ꍇ�F�i�o���� / ����) * -1
          ln_case_qty_minus := TRUNC((lt_singly_qty_sum / in_case_in_qty)) * -1;
        ELSE
          -- ��L�ȊO�̏ꍇ�F�i(�o���� / ����) * -1) +1
          ln_case_qty_minus := (TRUNC((lt_singly_qty_sum / in_case_in_qty)) * -1) +1;
        END IF;
--
        -- �P�[�X������������̃P�[�X���A�o�������v�Z
        lt_case_qty_sum   := lt_case_qty_sum   - ln_case_qty_minus;
        lt_singly_qty_sum := lt_singly_qty_sum + (in_case_in_qty * ln_case_qty_minus);
--
      END IF;
--
      -- �Z�o��̃P�[�X���A�o�����A������ʂ̂����ꂩ���}�C�i�X�̏ꍇ�̓G���[
      IF ( lt_case_qty_sum    < 0
        OR lt_singly_qty_sum  < 0
        OR lt_summary_qty_sum < 0)
      THEN
         -- �莝���ʎZ�o���ʃ}�C�i�X�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10585
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- �Z�o��̃P�[�X���A�o�����A������ʂ��S��0�̏ꍇ�́A�e�[�u������폜
      IF ( lt_case_qty_sum    = 0
       AND lt_singly_qty_sum  = 0
       AND lt_summary_qty_sum = 0 )
      THEN
        DELETE FROM xxcoi_lot_onhand_quantites xloq -- ���b�g�ʎ莝����
        WHERE  xloq.organization_id    = in_inv_org_id     -- �݌ɑg�DID
          AND  xloq.base_code          = iv_base_code      -- ���_�R�[�h
          AND  xloq.subinventory_code  = iv_subinv_code    -- �ۊǏꏊ�R�[�h
          AND  xloq.location_code      = iv_loc_code       -- ���P�[�V�����R�[�h
          AND  xloq.child_item_id      = in_child_item_id  -- �q�i��ID
          AND  (xloq.lot               = iv_lot
             OR (xloq.lot IS NULL AND iv_lot IS NULL)) -- ���b�g�i�ܖ������j
          AND  (xloq.difference_summary_code  = iv_diff_sum_code
             OR (xloq.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL)) -- �ŗL�L��
        ;
      -- ��L�ȊO�̏ꍇ�́A�X�V
      ELSE
        UPDATE xxcoi_lot_onhand_quantites xloq -- ���b�g�ʎ莝����
        SET    xloq.case_qty      = lt_case_qty_sum       -- �P�[�X��
              ,xloq.singly_qty    = lt_singly_qty_sum     -- �o����
              ,xloq.summary_qty   = lt_summary_qty_sum    -- �������
              ,xloq.last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
              ,xloq.last_update_date        = cd_last_update_date       -- �ŏI�X�V��
              ,xloq.last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
              ,xloq.request_id              = cn_request_id             -- �v��ID
              ,xloq.program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,xloq.program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
              ,xloq.program_update_date     = cd_program_update_date    -- �v���O�����X�V��
        WHERE  xloq.organization_id    = in_inv_org_id     -- �݌ɑg�DID
          AND  xloq.base_code          = iv_base_code      -- ���_�R�[�h
          AND  xloq.subinventory_code  = iv_subinv_code    -- �ۊǏꏊ�R�[�h
          AND  xloq.location_code      = iv_loc_code       -- ���P�[�V�����R�[�h
          AND  xloq.child_item_id      = in_child_item_id  -- �q�i��ID
          AND  (xloq.lot               = iv_lot
             OR (xloq.lot IS NULL AND iv_lot IS NULL))     -- ���b�g�i�ܖ������j
          AND  (xloq.difference_summary_code  = iv_diff_sum_code
             OR (xloq.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL))     -- �ŗL�L��
        ;
      END IF;
    END IF;
--
    -- ======================================
    -- �T�F�G���[����
    -- ======================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END ins_upd_del_lot_onhand;
--
/************************************************************************
 * Procedure Name  : GET_FRESH_CONDITION_DATE
 * Description     : �N�x��������Z�o
 ************************************************************************/
  PROCEDURE get_fresh_condition_date(
    id_use_by_date           IN  DATE             -- �ܖ�����
   ,id_product_date          IN  DATE             -- �����N����
   ,iv_fresh_condition       IN  VARCHAR2         -- �N�x����
   ,od_fresh_condition_date  OUT DATE             -- �N�x�������
   ,ov_errbuf                OUT VARCHAR2         -- �G���[���b�Z�[�W
   ,ov_retcode               OUT VARCHAR2         -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg                OUT VARCHAR2         -- ���[�U�[�E�G���[���b�Z�[�W
  )IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_fresh_condition_date'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�W�p�萔
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- �A�v���P�[�V�����Z�k��
    cv_err_msg_xxcoi1_00011   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00011'; -- �Ɩ����t���擾�G���[
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00024'; -- ���̓p�����[�^���ݒ�G���[
    cv_err_msg_xxcoi1_10588   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10588'; -- �ܖ�����
    cv_err_msg_xxcoi1_10589   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10589'; -- �����N����
    cv_err_msg_xxcoi1_10590   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10590'; -- �N�x����
    cv_err_msg_xxcoi1_10591   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10591'; -- �N�x�������擾�G���[
--
    cv_msg_tkn_param1         CONSTANT VARCHAR2(13)  := 'PARAM1';           -- �g�[�N���F�p�����[�^�P
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(13)  := 'IN_PARAM_NAME';    -- �g�[�N���F���̓p�����[�^
--
    cv_freshness_condition    CONSTANT VARCHAR2(30)  := 'XXCOI1_FRESHNESS_CONDITION'; -- �Q�ƃ^�C�v�F�N�x����
--
    cv_fresh_con_type_0       CONSTANT VARCHAR2(1)   := '0'; -- �N�x�����^�C�v�F'0'�i��ʁj
    cv_fresh_con_type_1       CONSTANT VARCHAR2(1)   := '1'; -- �N�x�����^�C�v�F'1'�i�ܖ�������j
    cv_fresh_con_type_2       CONSTANT VARCHAR2(1)   := '2'; -- �N�x�����^�C�v�F'2'�i��������j
    cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y'; -- �t���O:Y
--
    -- *** ���[�J���ϐ� ***
    lt_fresh_condition_type   fnd_lookup_values.attribute1%TYPE;  -- �N�x�����^�C�v
    lt_standard_value         fnd_lookup_values.attribute2%TYPE;  -- ��l
    lt_adjusted_value         fnd_lookup_values.attribute3%TYPE;  -- �����l
    ld_proc_date              DATE; -- �Ɩ����t
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    lt_fresh_condition_type  := NULL;  -- �N�x�����^�C�v
    lt_standard_value        := NULL;  -- ��l
    lt_adjusted_value        := NULL;  -- �����l
    ld_proc_date             := NULL;  -- �Ɩ����t
--
    -- ======================================
    -- �P�F��������
    -- ======================================
    -- �ܖ�������NULL�̏ꍇ
    IF ( id_use_by_date IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10588 -- �ܖ�����
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �����N������NULL�̏ꍇ
    IF ( id_product_date IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10589 -- �����N����
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    
--
    -- �N�x������NULL�̏ꍇ
    IF ( iv_fresh_condition IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10590 -- �N�x����
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ɩ����t���擾
    ld_proc_date := xxccp_common_pkg2.get_process_date;
    -- �擾�ł��Ȃ��ꍇ�́A�G���[
    IF ( ld_proc_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00011
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- �Q�F�N�x�������擾
    -- ======================================
    BEGIN
      SELECT flv.attribute1    fresh_condition_type -- �N�x�����^�C�v
            ,flv.attribute2    standard_value       -- ��l
            ,flv.attribute3    adjusted_value       -- �����l
      INTO   lt_fresh_condition_type -- �N�x�����^�C�v
            ,lt_standard_value       -- ��l
            ,lt_adjusted_value       -- �����l
      FROM   fnd_lookup_values  flv    -- �Q�ƃ^�C�v
      WHERE  flv.lookup_type         = cv_freshness_condition -- �^�C�v
        AND  flv.language            = USERENV('LANG')        -- ����
        AND  flv.lookup_code         = iv_fresh_condition     -- �R�[�h
        AND  flv.enabled_flag        = cv_flag_y              -- �L���t���O
        AND  ld_proc_date BETWEEN NVL(flv.start_date_active,ld_proc_date) -- �L���J�n��
                          AND     NVL(flv.end_date_active,ld_proc_date)   -- �L���I����
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�x�������擾�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10591
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => iv_fresh_condition -- IN�p�����[�^.�N�x����
                    );
      lv_errbuf := SQLERRM;
      RAISE global_process_expt;
    END;
--
    -- ======================================
    -- �R�F�N�x��������Z�o
    -- ======================================
    -- �N�x�����^�C�v = '0' (���) �̏ꍇ
    IF ( lt_fresh_condition_type = cv_fresh_con_type_0 ) THEN
      od_fresh_condition_date
        := id_use_by_date               -- �ܖ�����
         + NVL( lt_standard_value, 0 )  -- ��l
         + NVL( lt_adjusted_value, 0 ); -- �����l
--
    -- �N�x�����^�C�v = '1' (�ܖ������) �̏ꍇ
    ELSIF ( lt_fresh_condition_type = cv_fresh_con_type_1 ) THEN
      od_fresh_condition_date
        := id_product_date              -- �����N����
         + TRUNC((id_use_by_date - id_product_date) / lt_standard_value) -- (�ܖ����� - �����N����) / ��l
         + NVL( lt_adjusted_value, 0 ); -- �����l
    -- �N�x�����^�C�v = '2' (�������) �̏ꍇ
    ELSIF ( lt_fresh_condition_type = cv_fresh_con_type_2 ) THEN
      od_fresh_condition_date
        := id_product_date              -- �����N����
         + NVL( lt_standard_value, 0 )  -- ��l
         + NVL( lt_adjusted_value, 0 ); -- �����l
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_fresh_condition_date;
--
/************************************************************************
 * Procedure Name  : GET_RESERVED_QUANTITY
 * Description     : �����\���Z�o
 ************************************************************************/
  PROCEDURE get_reserved_quantity(
    in_inv_org_id       IN  NUMBER           -- �݌ɑg�DID
   ,iv_base_code        IN  VARCHAR2         -- ���_�R�[�h
   ,iv_subinv_code      IN  VARCHAR2         -- �ۊǏꏊ�R�[�h
   ,iv_loc_code         IN  VARCHAR2         -- ���P�[�V�����R�[�h
   ,in_child_item_id    IN  NUMBER           -- �q�i��ID
   ,iv_lot              IN  VARCHAR2         -- ���b�g(�ܖ�����)
   ,iv_diff_sum_code    IN  VARCHAR2         -- �ŗL�L��
   ,on_case_in_qty      OUT NUMBER           -- ����
   ,on_case_qty         OUT NUMBER           -- �P�[�X��
   ,on_singly_qty       OUT NUMBER           -- �o����
   ,on_summary_qty      OUT NUMBER           -- �������
   ,ov_errbuf           OUT VARCHAR2         -- �G���[���b�Z�[�W
   ,ov_retcode          OUT VARCHAR2         -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg           OUT VARCHAR2         -- ���[�U�[�E�G���[���b�Z�[�W
  )IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_reserved_quantity'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�W�p�萔
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- �A�v���P�[�V�����Z�k��
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00024'; -- ���̓p�����[�^���ݒ�G���[
    cv_err_msg_xxcoi1_00032   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00032'; -- �v���t�@�C���擾�G���[
    cv_err_msg_xxcoi1_10502   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10502'; -- ���_�R�[�h
    cv_err_msg_xxcoi1_10503   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10503'; -- �ۊǏꏊ�R�[�h
    cv_err_msg_xxcoi1_10514   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10514'; -- �݌ɑg�DID
    cv_err_msg_xxcoi1_10581   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10581'; -- ���P�[�V�����R�[�h
    cv_err_msg_xxcoi1_10582   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10582'; -- �q�i��ID
    cv_err_msg_xxcoi1_10585   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10585'; -- �莝���ʎZ�o���ʃ}�C�i�X�G���[
    cv_err_msg_xxcoi1_10592   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10592'; -- ���b�g�ʎ莝���ʎ擾�G���[
--
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(13)  := 'IN_PARAM_NAME';    -- �g�[�N���F���̓p�����[�^
    cv_msg_tkn_pro_tok        CONSTANT VARCHAR2(13)  := 'PRO_TOK';          -- �g�[�N���F�v���t�@�C��
--
    cv_org_id                 CONSTANT VARCHAR2(13)  := 'ORG_ID';           -- MO:�c�ƒP��
--
    cv_shipping_status_10     CONSTANT VARCHAR2(2)   := '10';               -- �o�׏��X�e�[�^�X�F10�i�������j
    cv_shipping_status_20     CONSTANT VARCHAR2(2)   := '20';               -- �o�׏��X�e�[�^�X�F20�i�����ρj
    cv_shipping_status_25     CONSTANT VARCHAR2(2)   := '25';               -- �o�׏��X�e�[�^�X�F25�i�o�׉��m��j
--
    cv_lot_tran_kbn_9         CONSTANT VARCHAR2(1)   := '9';                -- ���b�g�ʎ���쐬�敪�F9(�ΏۊO)
--
    cv_xxcoi016a06c           CONSTANT VARCHAR2(15)  := 'XXCOI016A06C';     -- ���b�g�ʏo�׏��쐬
--
    -- *** ���[�J���ϐ� ***
    lt_case_in_qty     xxcoi_lot_onhand_quantites.case_in_qty%TYPE; -- ����
    lt_case_qty        xxcoi_lot_onhand_quantites.case_qty%TYPE;    -- �P�[�X��
    lt_singly_qty      xxcoi_lot_onhand_quantites.singly_qty%TYPE;  -- �o����
    lt_summary_qty     xxcoi_lot_onhand_quantites.summary_qty%TYPE; -- �������
    lt_case_qty_sum    xxcoi_lot_onhand_quantites.case_qty%TYPE;    -- �P�[�X���i���v�j
    lt_singly_qty_sum  xxcoi_lot_onhand_quantites.singly_qty%TYPE;  -- �o�����i���v�j
    lt_summary_qty_sum xxcoi_lot_onhand_quantites.summary_qty%TYPE; -- ������ʁi���v�j
    lt_org_id          fnd_profile_option_values.profile_option_value%TYPE; -- �c�ƒP��
    ln_case_qty_minus  NUMBER;      -- �P�[�X���i�������v�Z�p�j
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
  BEGIN
--
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    lt_case_in_qty     := NULL; -- ����
    lt_case_qty        := NULL; -- �P�[�X��
    lt_singly_qty      := NULL; -- �o����
    lt_summary_qty     := NULL; -- �������
    lt_case_qty_sum    := NULL; -- �P�[�X���i���v�j
    lt_singly_qty_sum  := NULL; -- �o�����i���v�j
    lt_summary_qty_sum := NULL; -- ������ʁi���v�j
    ln_case_qty_minus  := NULL; -- �������P�[�X��
    lt_org_id          := NULL; -- �c�ƒP��
--
    -- ======================================
    -- �P�F��������
    -- ======================================
    -- ���̓p�����[�^�u�݌ɑg�DID�v��NULL�̏ꍇ
    IF ( in_inv_org_id IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10514 -- �݌ɑg�DID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u���_�R�[�h�v��NULL�̏ꍇ
    IF ( iv_base_code IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10502 -- ���_�R�[�h
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�ۊǏꏊ�R�[�h�v��NULL�̏ꍇ
    IF ( iv_subinv_code IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10503 -- �ۊǏꏊ�R�[�h
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u���P�[�V�����R�[�h�v��NULL�̏ꍇ
    IF ( iv_loc_code IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10581 -- ���P�[�V�����R�[�h
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�q�i��ID�v��NULL�̏ꍇ
    IF ( in_child_item_id IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W��ݒ�
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10582 -- �q�i��ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �v���t�@�C���uMO:�c�ƒP�ʁv���擾
    lt_org_id := FND_PROFILE.VALUE(cv_org_id);
    IF ( lt_org_id IS NULL ) THEN
      -- �v���t�@�C���l�擾�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00032
                     ,iv_token_name1  => cv_msg_tkn_pro_tok
                     ,iv_token_value1 => cv_org_id
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- �Q�F�莝���ʏ��擾
    -- ======================================
    BEGIN
      -- ���b�g�莝���ʏ����擾���܂�
      SELECT xloq.case_in_qty case_in_qty -- ����
            ,xloq.case_qty    case_qty    -- �P�[�X��
            ,xloq.singly_qty  singly_qty  -- �o����
            ,xloq.summary_qty summary_qty -- �������
      INTO   lt_case_in_qty -- ����
            ,lt_case_qty    -- �P�[�X��
            ,lt_singly_qty  -- �o����
            ,lt_summary_qty -- �������
      FROM   xxcoi_lot_onhand_quantites  xloq  -- ���b�g�ʎ莝����
      WHERE  xloq.organization_id    = in_inv_org_id     -- �݌ɑg�DID
        AND  xloq.base_code          = iv_base_code      -- ���_�R�[�h
        AND  xloq.subinventory_code  = iv_subinv_code    -- �ۊǏꏊ�R�[�h
        AND  xloq.location_code      = iv_loc_code       -- ���P�[�V�����R�[�h
        AND  xloq.child_item_id      = in_child_item_id  -- �q�i��ID
        AND  (xloq.lot               = iv_lot
           OR (xloq.lot IS NULL AND iv_lot IS NULL))     -- ���b�g�i�ܖ������j
        AND  (xloq.difference_summary_code  = iv_diff_sum_code
           OR (xloq.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL))     -- �ŗL�L��
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���b�g�ʎ莝���ʎ擾�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10592
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ======================================
    -- �R�F�������擾
    -- ======================================
    -- ���������擾
    SELECT NVL(SUM(xlri.case_qty), 0)    case_qty_sum    -- �P�[�X���i���v�j
          ,NVL(SUM(xlri.singly_qty), 0)  singly_qty_sum  -- �o�����i���v�j
          ,NVL(SUM(xlri.summary_qty), 0) summary_qty_sum -- ������ʁi���v�j
    INTO   lt_case_qty_sum                               -- �P�[�X���i���v�j
          ,lt_singly_qty_sum                             -- �o�����i���v�j
          ,lt_summary_qty_sum                            -- ������ʁi���v�j
    FROM   xxcoi_lot_reserve_info  xlri                  -- ���b�g�ʈ������
    WHERE  xlri.shipping_status    IN ( cv_shipping_status_10, cv_shipping_status_20, cv_shipping_status_25 ) -- �o�׏��X�e�[�^�X
--
      AND  xlri.org_id             = lt_org_id             -- �c�ƒP��
      AND  xlri.base_code          = iv_base_code          -- ���_�R�[�h
      AND  xlri.whse_code          = iv_subinv_code        -- �ۊǏꏊ�R�[�h
      AND  xlri.location_code      = iv_loc_code           -- ���P�[�V�����R�[�h
      AND  xlri.item_id            = in_child_item_id      -- �q�i��ID
      AND  (xlri.lot               = iv_lot
         OR (xlri.lot IS NULL AND iv_lot IS NULL))         -- ���b�g�i�ܖ������j
      AND  (xlri.difference_summary_code  = iv_diff_sum_code
         OR (xlri.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL))  -- �ŗL�L��
    ;
--
    -- ======================================
    -- 3-1.���b�g�ʎ��TEMP���ݐ��擾
    -- ======================================
--
    -- ======================================
    -- �S�F�����\���Z�o
    -- ======================================
    -- �P�[�X���A�o�����A������ʂ̎Z�o
    lt_case_qty_sum    := lt_case_qty    - lt_case_qty_sum;    -- �P�[�X��
    lt_singly_qty_sum  := lt_singly_qty  - lt_singly_qty_sum;  -- �o����
    lt_summary_qty_sum := lt_summary_qty - lt_summary_qty_sum; -- �������
--
    -- �P�[�X�����}�C�i�X�̏ꍇ�̓G���[
    IF ( lt_case_qty_sum  < 0 ) THEN
      -- �莝���ʎZ�o���ʃ}�C�i�X�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10585
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �o�������}�C�i�X�̏ꍇ�A�P�[�X��������
    IF ( lt_singly_qty_sum < 0 ) THEN
      -- �������P�[�X�����Z�o
      IF ( MOD(lt_singly_qty_sum,lt_case_in_qty) = 0 ) THEN
        -- �o�����������̔{���̏ꍇ�F�i�o���� / ����) * -1
        ln_case_qty_minus := TRUNC((lt_singly_qty_sum / lt_case_in_qty)) * -1;
      ELSE
        -- ��L�ȊO�̏ꍇ�F�i(�o���� / ����) * -1) +1
        ln_case_qty_minus := (TRUNC((lt_singly_qty_sum / lt_case_in_qty)) * -1) +1;
      END IF;
--
      -- �P�[�X������������̃P�[�X���A�o�������v�Z
      lt_case_qty_sum   := lt_case_qty_sum   - ln_case_qty_minus;
      lt_singly_qty_sum := lt_singly_qty_sum + (lt_case_in_qty * ln_case_qty_minus);
--
    END IF;
--
    -- �Z�o��̃P�[�X���A�o�����A������ʂ̂����ꂩ���}�C�i�X�̏ꍇ�̓G���[
    IF ( lt_case_qty_sum    < 0
      OR lt_singly_qty_sum  < 0
      OR lt_summary_qty_sum < 0)
    THEN
       -- �莝���ʎZ�o���ʃ}�C�i�X�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10585
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- �T�F�߂�l�ݒ�
    -- ======================================
    on_case_in_qty := lt_case_in_qty;     -- ����
    on_case_qty    := lt_case_qty_sum;    -- �P�[�X��
    on_singly_qty  := lt_singly_qty_sum;  -- �o����
    on_summary_qty := lt_summary_qty_sum; -- �������
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_reserved_quantity;
--
/************************************************************************
 * Function Name   : GET_FRESH_CONDITION_DATE_F
 * Description     : �N�x��������Z�o(�t�@���N�V�����^)
 ************************************************************************/
--
  FUNCTION get_fresh_condition_date_f(
    id_use_by_date     IN  DATE     -- �ܖ�����
   ,id_product_date    IN  DATE     -- �����N����
   ,iv_fresh_condition IN  VARCHAR2 -- �N�x����
  ) RETURN DATE
  IS
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
    global_process_expt EXCEPTION; -- ���������ʗ�O
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ld_return DATE; -- �߂�l
--
  BEGIN
    -- �ϐ�������
    ld_return := NULL;
--
    -- ���ʊ֐��F�u�N�x��������Z�o�v���g�p���N�x�����𓱏o
    xxcoi_common_pkg.get_fresh_condition_date(
      id_use_by_date          => id_use_by_date     -- �ܖ�����
     ,id_product_date         => id_product_date    -- �����N����
     ,iv_fresh_condition      => iv_fresh_condition -- �N�x����
     ,od_fresh_condition_date => ld_return          -- �N�x�������
     ,ov_errbuf               => lv_errbuf          -- �G���[���b�Z�[�W
     ,ov_retcode              => lv_retcode         -- ���^�[���E�R�[�h(0:����A2:�G���[)
     ,ov_errmsg               => lv_errmsg          -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    -- �߂�l�Z�b�g
    IF ( lv_retcode <> cv_status_normal ) THEN
      RETURN NULL;
    ELSE
      RETURN ld_return;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_fresh_condition_date_f;
--
-- == 2014/11/07 Ver1.12 Y.Nagasue ADD END ======================================================
END XXCOI_COMMON_PKG;
/
