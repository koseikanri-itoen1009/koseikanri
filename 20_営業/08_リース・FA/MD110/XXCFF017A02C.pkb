CREATE OR REPLACE PACKAGE BODY APPS.XXCFF017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A02C (body)
 * Description      : ���̋@����CSV�o��
 * MD.050           : ���̋@����CSV�o�� (MD050_CFF_017A02)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_csv             ���̋@������񒊏o����(A-2)�A���̋@����CSV�o�͏���(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-4)
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/06/23    1.0   T.Kobori         main�V�K�쐬
 *  2014/06/30    1.1   T.Kobori         ���ڍ폜  1.���z���[�X�� 2.�ă��[�X��
 *  2014/07/04    1.2   T.Kobori         ���ڒǉ�  1.�d����R�[�h(�o�̓t�@�C��)
 *  2014/07/09    1.3   T.Kobori         ���ڒǉ�  1.�d����R�[�h(���̓p�����[�^)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  init_err_expt               EXCEPTION;      -- ���������G���[
  no_data_warn_expt           EXCEPTION;      -- �Ώۃf�[�^�Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFF017A02C';              -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcff          CONSTANT VARCHAR2(10)  := 'XXCFF';                     -- XXCFF
  -- ���t����
  cv_format_YMD               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  cv_format_std               CONSTANT VARCHAR2(50)  := 'yyyy/mm/dd hh24:mi:ss';
  -- ���蕶��
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- �����񊇂�
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- �J���}
  -- ���b�Z�[�W�R�[�h
  cv_msg_cff_00062            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00062';          -- �Ώۃf�[�^����
  cv_msg_cff_00220            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00220';          -- ���̓p�����[�^
  cv_msg_cff_00226            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00226';          -- �K�{�`�F�b�N�G���[(�����R�[�h)
  cv_msg_cff_50239            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50239';          -- ���b�Z�[�W�p������(�����敪)
  cv_msg_cff_50240            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50240';          -- ���b�Z�[�W�p������(�@��敪)
  cv_msg_cff_50010            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50010';          -- ���b�Z�[�W�p������(�����R�[�h)
  cv_msg_cff_50013            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50013';          -- ���b�Z�[�W�p������(�����X�e�[�^�X)
  cv_msg_cff_50243            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50243';          -- ���b�Z�[�W�p������(�Ǘ�����)
  cv_msg_cff_50177            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50177';          -- ���b�Z�[�W�p������(���[�J��)
  cv_msg_cff_50178            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50178';          -- ���b�Z�[�W�p������(�@��)
  cv_msg_cff_50246            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50246';          -- ���b�Z�[�W�p������(�\���n)
  cv_msg_cff_50247            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50247';          -- ���b�Z�[�W�p������(���Ƌ��p�� FROM)
  cv_msg_cff_50248            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50248';          -- ���b�Z�[�W�p������(���Ƌ��p�� TO)
  cv_msg_cff_50249            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50249';          -- ���b�Z�[�W�p������(�����p�� FROM)
  cv_msg_cff_50250            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50250';          -- ���b�Z�[�W�p������(�����p�� TO)
  cv_msg_cff_50251            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50251';          -- ���b�Z�[�W�p������(���������敪)
  cv_msg_cff_50252            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50252';          -- ���b�Z�[�W�p������(���������� FROM)
  cv_msg_cff_50253            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50253';          -- ���b�Z�[�W�p������(���������� TO)
  cv_msg_cff_50276            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50276';          -- ���b�Z�[�W�p������(�d����R�[�h)
  cv_msg_cff_50254            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50254';          -- ���̋@����CSV�o�̓w�b�_�m�[�g
  cv_msg_cff_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- �Ώی������b�Z�[�W
  cv_msg_cff_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- �����������b�Z�[�W
  cv_msg_cff_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- �G���[�������b�Z�[�W
  cv_msg_cff_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';          -- �X�L�b�v�������b�Z�[�W
  cv_msg_cff_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- ����I�����b�Z�[�W
  cv_msg_cff_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';          -- �x�����b�Z�[�W
  cv_msg_cff_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N���b�Z�[�W
  -- �g�[�N��
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- ���̓p�����[�^��
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- ���̓p�����[�^�l
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- ����
  -- �����敪
  cv_search_type_1            CONSTANT VARCHAR2(1)   := '1';                         -- �ŐV
  cv_search_type_2            CONSTANT VARCHAR2(1)   := '2';                         -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_search_type                     VARCHAR2(1);                                       -- �����敪
  gt_machine_type                    PO_HAZARD_CLASSES_TL.HAZARD_CLASS%TYPE;            -- �@��敪
  gt_object_code                     XXCFF_VD_OBJECT_HEADERS.OBJECT_CODE%TYPE;          -- �����R�[�h
  gv_object_status                   VARCHAR2(3);                                       -- �����X�e�[�^�X
  gt_department_code                 FND_FLEX_VALUES.FLEX_VALUE%TYPE;                   -- �Ǘ�����
  gt_manufacturer_name               XXCFF_VD_OBJECT_HEADERS.MANUFACTURER_NAME%TYPE;    -- ���[�J��
  gt_model                           PO_UN_NUMBERS_TL.UN_NUMBER%TYPE;                   -- �@��
  gt_dclr_place                      FND_FLEX_VALUES.FLEX_VALUE%TYPE;                   -- �\���n
  gd_date_placed_in_service_from     DATE;                                              -- ���Ƌ��p�� FROM
  gd_date_placed_in_service_to       DATE;                                              -- ���Ƌ��p�� TO
  gd_date_retired_from               DATE;                                              -- �����p�� FROM
  gd_date_retired_to                 DATE;                                              -- �����p�� TO
  gv_process_type                    VARCHAR2(3);                                       -- ���������敪
  gd_process_date_from               DATE;                                              -- ���������� FROM
  gd_process_date_to                 DATE;                                              -- ���������� TO
  gt_vendor_code                     PO_VENDORS.SEGMENT1%TYPE;                          -- �d����R�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- ���̋@�������擾�J�[�\��
  CURSOR get_vd_object_info_cur
  IS
    SELECT
        vohd.object_code                              AS  object_code             -- �����R�[�h
       ,NULL                                          AS  history_num             -- ����ԍ�
       ,NULL                                          AS  process_type            -- �����敪
       ,NULL                                          AS  process_date            -- ������
       ,vohd.object_status                            AS  object_status           -- �����X�e�[�^�X
       ,vohd.owner_company_type                       AS  owner_company_type      -- �{��/�H��敪
       ,vohd.department_code                          AS  department_code         -- �Ǘ�����
       ,vohd.machine_type                             AS  machine_type            -- �@��敪
 -- 2014/07/04 ADD START
       ,vohd.vendor_code                              AS  vendor_code             -- �d����R�[�h
 -- 2014/07/04 ADD END
       ,vohd.manufacturer_name                        AS  manufacturer_name       -- ���[�J��
       ,vohd.model                                    AS  model                   -- �@��
       ,vohd.age_type                                 AS  age_type                -- �N��
       ,vohd.customer_code                            AS  customer_code           -- �ڋq�R�[�h
       ,vohd.quantity                                 AS  quantity                -- ����
       ,vohd.date_placed_in_service                   AS  date_placed_in_service  -- ���Ƌ��p��
       ,vohd.assets_cost                              AS  assets_cost             -- �擾���i
 -- 2014/06/30 DEL START
 --      ,vohd.month_lease_charge                       AS  month_lease_charge      -- ���z���[�X��
 --      ,vohd.re_lease_charge                          AS  re_lease_charge         -- �ă��[�X��
 -- 2014/06/30 DEL END
       ,NVL(vohd.assets_date,vohd.date_placed_in_service)  AS  assets_date        -- NVL(�擾��,���Ƌ��p��)
       ,vohd.moved_date                               AS  moved_date              -- �ړ���
       ,vohd.installation_place                       AS  installation_place      -- �ݒu��
       ,vohd.installation_address                     AS  installation_address    -- �ݒu�ꏊ
       ,vohd.dclr_place                               AS  dclr_place              -- �\���n
       ,vohd.location                                 AS  location                -- ���Ə�
       ,vohd.date_retired                             AS  date_retired            -- ������p��
       ,vohd.proceeds_of_sale                         AS  proceeds_of_sale        -- ���p���z
       ,vohd.cost_of_removal                          AS  cost_of_removal         -- �P����p
       ,vohd.retired_flag                             AS  retired_flag            -- �����p�m��t���O
       ,vohd.ib_if_date                               AS  ib_if_date              -- �ݒu�x�[�X���A�g��
       ,NULL                                          AS  fa_if_date              -- FA���A�g��
       ,vohd.last_updated_by                          AS  last_updated_by         -- �ŏI�X�V��
    FROM
        xxcff_vd_object_headers vohd  --���̋@�����Ǘ�
    WHERE vohd.machine_type           = gt_machine_type                                                  -- �@��敪
    AND vohd.object_code              = NVL(gt_object_code,vohd.object_code)                             -- �����R�[�h
    AND vohd.object_status            = NVL(gv_object_status,vohd.object_status)                         -- �����X�e�[�^�X
    AND vohd.department_code          = NVL(gt_department_code,vohd.department_code)                     -- �Ǘ�����
    AND vohd.manufacturer_name        = NVL(gt_manufacturer_name,vohd.manufacturer_name)                 -- ���[�J��
    AND vohd.model                    = NVL(gt_model,vohd.model)                                         -- �@��
    AND vohd.dclr_place               = NVL(gt_dclr_place,vohd.dclr_place)                               -- �\���n
    AND (  (gd_date_placed_in_service_from IS NULL
        AND gd_date_placed_in_service_to IS NULL)                                              -- ���Ƌ��p��������
        OR (vohd.date_placed_in_service     >= NVL(gd_date_placed_in_service_from,vohd.date_placed_in_service)   -- ���Ƌ��p�� FROM
        AND vohd.date_placed_in_service     <= NVL(gd_date_placed_in_service_to,vohd.date_placed_in_service))    -- ���Ƌ��p�� TO
        )
    AND (  (gd_date_retired_from IS NULL
        AND gd_date_retired_to IS NULL)                                                        -- �����p��������
        OR (vohd.date_retired             >= NVL(gd_date_retired_from,vohd.date_retired)                 -- �����p�� FROM
        AND vohd.date_retired             <= NVL(gd_date_retired_to,vohd.date_retired))                  -- �����p�� TO
        )
 -- 2014/07/09 ADD START
    AND (  gt_vendor_code IS NULL
        OR vohd.vendor_code           = gt_vendor_code                                                   -- �d����R�[�h
        )
 -- 2014/07/09 ADD END
    AND gv_search_type           = cv_search_type_1                                            -- �����敪(�ŐV)
    UNION
    SELECT
        vohi.object_code                              AS  object_code             -- �����R�[�h
       ,vohi.history_num                              AS  history_num             -- ����ԍ�
       ,vohi.process_type                             AS  process_type            -- �����敪
       ,vohi.process_date                             AS  process_date            -- ������
       ,vohi.object_status                            AS  object_status           -- �����X�e�[�^�X
       ,vohi.owner_company_type                       AS  owner_company_type      -- �{��/�H��敪
       ,vohi.department_code                          AS  department_code         -- �Ǘ�����
       ,vohi.machine_type                             AS  machine_type            -- �@��敪
 -- 2014/07/04 ADD START
       ,NULL                                          AS  vendor_code             -- �d����R�[�h
 -- 2014/07/04 ADD END
       ,vohi.manufacturer_name                        AS  manufacturer_name       -- ���[�J��
       ,vohi.model                                    AS  model                   -- �@��
       ,vohi.age_type                                 AS  age_type                -- �N��
       ,vohi.customer_code                            AS  customer_code           -- �ڋq�R�[�h
       ,vohi.quantity                                 AS  quantity                -- ����
       ,vohi.date_placed_in_service                   AS  date_placed_in_service  -- ���Ƌ��p��
       ,vohi.assets_cost                              AS  assets_cost             -- �擾���i
 -- 2014/06/30 DEL START
 --      ,vohi.month_lease_charge                       AS  month_lease_charge      -- ���z���[�X��
 --      ,vohi.re_lease_charge                          AS  re_lease_charge         -- �ă��[�X��
 -- 2014/06/30 DEL END
       ,NVL(vohi.assets_date,vohi.date_placed_in_service)  AS  assets_date             -- NVL(�擾��,���Ƌ��p��)
       ,vohi.moved_date                               AS  moved_date              -- �ړ���
       ,vohi.installation_place                       AS  installation_place      -- �ݒu��
       ,vohi.installation_address                     AS  installation_address    -- �ݒu�ꏊ
       ,vohi.dclr_place                               AS  dclr_place              -- �\���n
       ,vohi.location                                 AS  location                -- ���Ə�
       ,vohi.date_retired                             AS  date_retired            -- ������p��
       ,vohi.proceeds_of_sale                         AS  proceeds_of_sale        -- ���p���z
       ,vohi.cost_of_removal                          AS  cost_of_removal         -- �P����p
       ,vohi.retired_flag                             AS  retired_flag            -- �����p�m��t���O
       ,vohi.ib_if_date                               AS  ib_if_date              -- �ݒu�x�[�X���A�g��
       ,vohi.fa_if_date                               AS  fa_if_date              -- FA���A�g��
       ,vohi.last_updated_by                          AS  last_updated_by         -- �ŏI�X�V��
    FROM
        xxcff_vd_object_histories vohi  --���̋@��������
    WHERE vohi.machine_type           = gt_machine_type                                             -- �@��敪
    AND vohi.object_code              = gt_object_code                                              -- �����R�[�h
    AND vohi.object_status            = NVL(gv_object_status,vohi.object_status)                         -- �����X�e�[�^�X
    AND vohi.department_code          = NVL(gt_department_code,vohi.department_code)                     -- �Ǘ�����
    AND vohi.manufacturer_name        = NVL(gt_manufacturer_name,vohi.manufacturer_name)                 -- ���[�J��
    AND vohi.model                    = NVL(gt_model,vohi.model)                                         -- �@��
    AND vohi.dclr_place               = NVL(gt_dclr_place,vohi.dclr_place)                               -- �\���n
    AND (  (gd_date_placed_in_service_from IS NULL
        AND gd_date_placed_in_service_to IS NULL)                                              -- ���Ƌ��p��������
        OR (vohi.date_placed_in_service     >= NVL(gd_date_placed_in_service_from,vohi.date_placed_in_service)   -- ���Ƌ��p�� FROM
        AND vohi.date_placed_in_service     <= NVL(gd_date_placed_in_service_to,vohi.date_placed_in_service))    -- ���Ƌ��p�� TO
        )
    AND (  (gd_date_retired_from IS NULL
        AND gd_date_retired_to IS NULL)                                                        -- �����p��������
        OR (vohi.date_retired             >= NVL(gd_date_retired_from,vohi.date_retired)                 -- �����p�� FROM
        AND vohi.date_retired             <= NVL(gd_date_retired_to,vohi.date_retired))                  -- �����p�� TO
        )
    AND vohi.process_type             = NVL(gv_process_type,vohi.process_type)                           -- ���������敪
    AND (  (gd_process_date_from IS NULL
        AND gd_process_date_to IS NULL)                                                        -- ����������������
        OR (vohi.process_date             >= NVL(gd_process_date_from,vohi.process_date)                 -- ���������� FROM
        AND vohi.process_date             <= NVL(gd_process_date_to,vohi.process_date))                  -- ���������� TO
        )
    AND gv_search_type           = cv_search_type_2                                            -- �����敪(����)
    ORDER BY object_code         -- �����R�[�h
            ,history_num         -- ����ԍ�
    ;
    -- ���̋@�������J�[�\�����R�[�h�^
    get_vd_object_info_rec get_vd_object_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_search_type                  IN  VARCHAR2      -- 1.�����敪 
   ,iv_machine_type                 IN  VARCHAR2      -- 2.�@��敪
   ,iv_object_code                  IN  VARCHAR2      -- 3.�����R�[�h
   ,iv_object_status                IN  VARCHAR2      -- 4.�����X�e�[�^�X
   ,iv_department_code              IN  VARCHAR2      -- 5.�Ǘ�����
   ,iv_manufacturer_name            IN  VARCHAR2      -- 6.���[�J��
   ,iv_model                        IN  VARCHAR2      -- 7.�@��
   ,iv_dclr_place                   IN  VARCHAR2      -- 8.�\���n
   ,iv_date_placed_in_service_from  IN  DATE          -- 9.���Ƌ��p�� FROM
   ,iv_date_placed_in_service_to    IN  DATE          -- 10.���Ƌ��p�� TO
   ,iv_date_retired_from            IN  DATE          -- 11.�����p�� FROM
   ,iv_date_retired_to              IN  DATE          -- 12.�����p�� TO
   ,iv_process_type                 IN  VARCHAR2      -- 13.���������敪
   ,iv_process_date_from            IN  DATE          -- 14.���������� FROM
   ,iv_process_date_to              IN  DATE          -- 15.���������� TO
 -- 2014/07/09 ADD START
   ,iv_vendor_code                  IN  VARCHAR2      -- 16.�d����R�[�h
 -- 2014/07/09 ADD END
   ,ov_errbuf                       OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_param_name1                  VARCHAR2(1000);  -- ���̓p�����[�^��1
    lv_param_name2                  VARCHAR2(1000);  -- ���̓p�����[�^��2
    lv_param_name3                  VARCHAR2(1000);  -- ���̓p�����[�^��3
    lv_param_name4                  VARCHAR2(1000);  -- ���̓p�����[�^��4
    lv_param_name5                  VARCHAR2(1000);  -- ���̓p�����[�^��5
    lv_param_name6                  VARCHAR2(1000);  -- ���̓p�����[�^��6
    lv_param_name7                  VARCHAR2(1000);  -- ���̓p�����[�^��7
    lv_param_name8                  VARCHAR2(1000);  -- ���̓p�����[�^��8
    lv_param_name9                  VARCHAR2(1000);  -- ���̓p�����[�^��9
    lv_param_name10                 VARCHAR2(1000);  -- ���̓p�����[�^��10
    lv_param_name11                 VARCHAR2(1000);  -- ���̓p�����[�^��11
    lv_param_name12                 VARCHAR2(1000);  -- ���̓p�����[�^��12
    lv_param_name13                 VARCHAR2(1000);  -- ���̓p�����[�^��13
    lv_param_name14                 VARCHAR2(1000);  -- ���̓p�����[�^��14
    lv_param_name15                 VARCHAR2(1000);  -- ���̓p�����[�^��15
 -- 2014/07/09 ADD START
    lv_param_name16                 VARCHAR2(1000);  -- ���̓p�����[�^��16
 -- 2014/07/09 ADD END
    lv_search_type                  VARCHAR2(1000);  -- 1.�����敪 
    lv_machine_type                 VARCHAR2(1000);  -- 2.�@��敪
    lv_object_code                  VARCHAR2(1000);  -- 3.�����R�[�h
    lv_object_status                VARCHAR2(1000);  -- 4.�����X�e�[�^�X
    lv_department_code              VARCHAR2(1000);  -- 5.�Ǘ�����
    lv_manufacturer_name            VARCHAR2(1000);  -- 6.���[�J��
    lv_model                        VARCHAR2(1000);  -- 7.�@��
    lv_dclr_place                   VARCHAR2(1000);  -- 8.�\���n
    lv_date_placed_in_service_from  VARCHAR2(1000);  -- 9.���Ƌ��p�� FROM
    lv_date_placed_in_service_to    VARCHAR2(1000);  -- 10.���Ƌ��p�� TO
    lv_date_retired_from            VARCHAR2(1000);  -- 11.�����p�� FROM
    lv_date_retired_to              VARCHAR2(1000);  -- 12.�����p�� TO
    lv_process_type                 VARCHAR2(1000);  -- 13.���������敪
    lv_process_date_from            VARCHAR2(1000);  -- 14.���������� FROM
    lv_process_date_to              VARCHAR2(1000);  -- 15.���������� TO
 -- 2014/07/09 ADD START
    lv_vendor_code                  VARCHAR2(1000);  -- 16.�d����R�[�h
 -- 2014/07/09 ADD END
    lv_csv_header                   VARCHAR2(5000);  -- CSV�w�b�_���ڏo�͗p
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- 0.���̓p�����[�^�i�[
    --==============================================================
    gv_search_type                  := iv_search_type;                                         --1.�����敪
    gt_machine_type                 := iv_machine_type;                                        --2.�@��敪
    --3.�����R�[�h
    BEGIN
    gt_object_code := iv_object_code;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application  => cv_appl_name_xxcff   -- �A�v���P�[�V�����Z�k��
           ,iv_name         => cv_msg_cff_50010     -- ���b�Z�[�W�R�[�h
        );
        lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END;
    gv_object_status                := iv_object_status;                                       --4.�����X�e�[�^�X
    gt_department_code              := iv_department_code;                                     --5.�Ǘ�����
    gt_manufacturer_name            := iv_manufacturer_name;                                   --6.���[�J��
    gt_model                        := iv_model;                                               --7.�@��
    gt_dclr_place                   := iv_dclr_place;                                          --8.�\���n
    gd_date_placed_in_service_from  := iv_date_placed_in_service_from;                         --9.���Ƌ��p�� FROM
    gd_date_placed_in_service_to    := iv_date_placed_in_service_to;                           --10.���Ƌ��p�� TO
    gd_date_retired_from            := iv_date_retired_from;                                   --11.�����p�� FROM
    gd_date_retired_to              := iv_date_retired_to;                                     --12.�����p�� TO
    gv_process_type                 := iv_process_type;                                        --13.���������敪
    gd_process_date_from            := iv_process_date_from;                                   --14.���������� FROM
    gd_process_date_to              := iv_process_date_to;                                     --15.���������� TO
 -- 2014/07/09 ADD START
    gt_vendor_code                  := iv_vendor_code;                                         --16.�d����R�[�h
 -- 2014/07/09 ADD END
--
    --==============================================================
    -- 1.���̓p�����[�^�o��
    --==============================================================
    -- 1.�����敪
    lv_param_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50239               -- ���b�Z�[�W�R�[�h
                      );
    lv_search_type := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name1                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_search_type                 -- �g�[�N���l2
                      );
--
    -- 2.�@��敪
    lv_param_name2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50240               -- ���b�Z�[�W�R�[�h
                      );
    lv_machine_type := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name2                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_machine_type                -- �g�[�N���l2
                      );
--
    -- 3.�����R�[�h
    lv_param_name3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50010               -- ���b�Z�[�W�R�[�h
                      );
    lv_object_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name3                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_object_code                 -- �g�[�N���l2
                      );
--
    -- 4.�����X�e�[�^�X
    lv_param_name4 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50013               -- ���b�Z�[�W�R�[�h
                      );
    lv_object_status := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name4                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_object_status               -- �g�[�N���l2
                      );
--
    -- 5.�Ǘ�����
    lv_param_name5 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50243               -- ���b�Z�[�W�R�[�h
                      );
    lv_department_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name5                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_department_code             -- �g�[�N���l2
                      );
--
    -- 6.���[�J��
    lv_param_name6 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50177               -- ���b�Z�[�W�R�[�h
                      );
    lv_manufacturer_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name6                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_manufacturer_name           -- �g�[�N���l2
                      );
--
    -- 7.�@��
    lv_param_name7 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50178               -- ���b�Z�[�W�R�[�h
                      );
    lv_model := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name7                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_model                       -- �g �[�N���l2
                      );
--
    -- 8.�\���n
    lv_param_name8 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50246               -- ���b�Z�[�W�R�[�h
                      );
    lv_dclr_place := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name8                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_dclr_place                  -- �g�[�N���l2
                      );
--
    -- 9.���Ƌ��p�� FROM
    lv_param_name9 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50247               -- ���b�Z�[�W�R�[�h
                      );
    lv_date_placed_in_service_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name9                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_DATE(iv_date_placed_in_service_from,cv_format_YMD) -- �g�[�N���l2
                      );
--
    -- 10.���Ƌ��p�� TO
    lv_param_name10 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50248               -- ���b�Z�[�W�R�[�h
                      );
    lv_date_placed_in_service_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name10                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_DATE(iv_date_placed_in_service_to,cv_format_YMD)   -- �g�[�N���l2
                      );
--
    -- 11.�����p�� FROM
    lv_param_name11 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50249               -- ���b�Z�[�W�R�[�h
                      );
    lv_date_retired_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name11                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_DATE(iv_date_retired_from,cv_format_YMD)           -- �g�[�N���l2
                      );
--
    -- 12.�����p�� TO
    lv_param_name12 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50250               -- ���b�Z�[�W�R�[�h
                      );
    lv_date_retired_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name12                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_DATE(iv_date_retired_to,cv_format_YMD)             -- �g�[�N���l2
                      );
--
    -- 13.���������敪
    lv_param_name13 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50251               -- ���b�Z�[�W�R�[�h
                      );
    lv_process_type := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name13                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_process_type                -- �g�[�N���l2
                      );
--
    -- 14.���������� FROM
    lv_param_name14 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50252               -- ���b�Z�[�W�R�[�h
                      );
    lv_process_date_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name14                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_DATE(iv_process_date_from,cv_format_YMD)           -- �g�[�N���l2
                      );
--
    -- 15.���������� TO
    lv_param_name15 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50253               -- ���b�Z�[�W�R�[�h
                      );
    lv_process_date_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name15                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_DATE(iv_process_date_to,cv_format_YMD)             -- �g�[�N���l2
                      );
 -- 2014/07/09 ADD START
    -- 16.�d����R�[�h
    lv_param_name16 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50276               -- ���b�Z�[�W�R�[�h
                      );
    lv_vendor_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name16                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_vendor_code                 -- �g�[�N���l2
                      );
 -- 2014/07/09 ADD END
--
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''                             || CHR(10) ||
                 lv_search_type                 || CHR(10) ||      -- 1.�����敪
                 lv_machine_type                || CHR(10) ||      -- 2.�@��敪
                 lv_object_code                 || CHR(10) ||      -- 3.�����R�[�h
                 lv_object_status               || CHR(10) ||      -- 4.�����X�e�[�^�X
                 lv_department_code             || CHR(10) ||      -- 5.�Ǘ�����
                 lv_manufacturer_name           || CHR(10) ||      -- 6.���[�J��
                 lv_model                       || CHR(10) ||      -- 7.�@��
                 lv_dclr_place                  || CHR(10) ||      -- 8.�\���n
                 lv_date_placed_in_service_from || CHR(10) ||      -- 9.���Ƌ��p�� FROM
                 lv_date_placed_in_service_to   || CHR(10) ||      -- 10.���Ƌ��p�� TO
                 lv_date_retired_from           || CHR(10) ||      -- 11.�����p�� FROM
                 lv_date_retired_to             || CHR(10) ||      -- 12.�����p�� TO
                 lv_process_type                || CHR(10) ||      -- 13.���������敪
                 lv_process_date_from           || CHR(10) ||      -- 14.���������� FROM
 -- 2014/07/09 MOD START
 --                lv_process_date_to             || CHR(10)         -- 15.���������� TO
                 lv_process_date_to             || CHR(10) ||      -- 15.���������� TO
                 lv_vendor_code                 || CHR(10)         -- 16.�d����R�[�h
 -- 2014/07/09 ADD END
    );
--
    --==================================================
    -- 2.���̓p�����[�^�K�{�`�F�b�N
    --==================================================
    -- �����w�莞�ɁA�����R�[�h�������͂̏ꍇ�̓G���[
    IF( gv_search_type = cv_search_type_2 AND gt_object_code IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcff   -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cff_00226     -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 3.CSV�w�b�_���ڏo��
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_cff_50254     -- ���b�Z�[�W�R�[�h
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : ���̋@������񒊏o����(A-2)�A���̋@����CSV�o�͏���(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
--
    -- *** ���[�J���ϐ� ***
    lv_op_str            VARCHAR2(5000)  := NULL;   -- �o�͕�����i�[�p�ϐ�
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ���̋@������񒊏o����(A-2)
    -- ===============================
    << vd_object_info_loop >>
    FOR get_vd_object_info_rec IN get_vd_object_info_cur
    LOOP
      -- ===============================
      -- CSV�t�@�C���o��(A-3)
      -- ===============================
      -- �Ώی���
      gn_target_cnt := gn_target_cnt + 1;
--
      --�o�͕�����쐬
      lv_op_str :=                          cv_dqu || NULL                                          || cv_dqu ;   -- �ύX�敪
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.object_code            || cv_dqu ;   -- �����R�[�h
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.history_num            || cv_dqu ;   -- ����ԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.process_type           || cv_dqu ;   -- �����敪
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.process_date           || cv_dqu ;   -- ������
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.object_status          || cv_dqu ;   -- �����X�e�[�^�X
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.owner_company_type     || cv_dqu ;   -- �{��/�H��敪
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.department_code        || cv_dqu ;   -- �Ǘ�����
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.machine_type           || cv_dqu ;   -- �@��敪
 -- 2014/07/04 ADD START
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.vendor_code            || cv_dqu ;   -- �d����R�[�h
 -- 2014/07/04 ADD END
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.manufacturer_name      || cv_dqu ;   -- ���[�J��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.model                  || cv_dqu ;   -- �@��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.age_type               || cv_dqu ;   -- �N��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.customer_code          || cv_dqu ;   -- �ڋq�R�[�h
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.quantity               || cv_dqu ;   -- ����
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.date_placed_in_service || cv_dqu ;   -- ���Ƌ��p��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.assets_cost            || cv_dqu ;   -- �擾���i
 -- 2014/06/30 DEL START
 --     lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.month_lease_charge     || cv_dqu ;   -- ���z���[�X��
 --     lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.re_lease_charge        || cv_dqu ;   -- �ă��[�X��
 -- 2014/06/30 DEL END
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.assets_date            || cv_dqu ;   -- �擾��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.moved_date             || cv_dqu ;   -- �ړ���
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.installation_place     || cv_dqu ;   -- �ݒu��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.installation_address   || cv_dqu ;   -- �ݒu�ꏊ
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.dclr_place             || cv_dqu ;   -- �\���n
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.location               || cv_dqu ;   -- ���Ə�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.date_retired           || cv_dqu ;   -- ������p��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.proceeds_of_sale       || cv_dqu ;   -- ���p���z
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.cost_of_removal        || cv_dqu ;   -- �P����p
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.retired_flag           || cv_dqu ;   -- �����p�m��t���O
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.ib_if_date             || cv_dqu ;   -- �ݒu�x�[�X���A�g��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.fa_if_date             || cv_dqu ;   -- FA���A�g��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.last_updated_by        || cv_dqu ;   -- �]�ƈ��ԍ�
--
      -- ===============================
      -- 2.CSV�t�@�C���o��
      -- ===============================
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_op_str
      );
      -- ��������
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP vd_object_info_loop;
--
    -- �Ώۃf�[�^�Ȃ��x��
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcff
                      ,iv_name         => cv_msg_cff_00062
                     );
      ov_errbuf  := gv_out_msg;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_search_type                  IN  VARCHAR2     -- 1.�����敪 
   ,iv_machine_type                 IN  VARCHAR2     -- 2.�@��敪
   ,iv_object_code                  IN  VARCHAR2     -- 3.�����R�[�h
   ,iv_object_status                IN  VARCHAR2     -- 4.�����X�e�[�^�X
   ,iv_department_code              IN  VARCHAR2     -- 5.�Ǘ�����
   ,iv_manufacturer_name            IN  VARCHAR2     -- 6.���[�J��
   ,iv_model                        IN  VARCHAR2     -- 7.�@��
   ,iv_dclr_place                   IN  VARCHAR2     -- 8.�\���n
   ,iv_date_placed_in_service_from  IN  DATE         -- 9.���Ƌ��p�� FROM
   ,iv_date_placed_in_service_to    IN  DATE         -- 10.���Ƌ��p�� TO
   ,iv_date_retired_from            IN  DATE         -- 11.�����p�� FROM
   ,iv_date_retired_to              IN  DATE         -- 12.�����p�� TO
   ,iv_process_type                 IN  VARCHAR2     -- 13.���������敪
   ,iv_process_date_from            IN  DATE         -- 14.���������� FROM
   ,iv_process_date_to              IN  DATE         -- 15.���������� TO
 -- 2014/07/09 ADD START
   ,iv_vendor_code                  IN  VARCHAR2     -- 16.�d����R�[�h
 -- 2014/07/09 ADD END
   ,ov_errbuf                       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_search_type                 => iv_search_type                 -- 1.�����敪 
     ,iv_machine_type                => iv_machine_type                -- 2.�@��敪
     ,iv_object_code                 => iv_object_code                 -- 3.�����R�[�h
     ,iv_object_status               => iv_object_status               -- 4.�����X�e�[�^�X
     ,iv_department_code             => iv_department_code             -- 5.�Ǘ�����
     ,iv_manufacturer_name           => iv_manufacturer_name           -- 6.���[�J��
     ,iv_model                       => iv_model                       -- 7.�@��
     ,iv_dclr_place                  => iv_dclr_place                  -- 8.�\���n
     ,iv_date_placed_in_service_from => iv_date_placed_in_service_from -- 9.���Ƌ��p�� FROM
     ,iv_date_placed_in_service_to   => iv_date_placed_in_service_to   -- 10.���Ƌ��p�� TO
     ,iv_date_retired_from           => iv_date_retired_from           -- 11.�����p�� FROM
     ,iv_date_retired_to             => iv_date_retired_to             -- 12.�����p�� TO
     ,iv_process_type                => iv_process_type                -- 13.���������敪
     ,iv_process_date_from           => iv_process_date_from           -- 14.���������� FROM
     ,iv_process_date_to             => iv_process_date_to             -- 15.���������� TO
 -- 2014/07/09 ADD START
     ,iv_vendor_code                 => iv_vendor_code                 -- 16.�d����R�[�h
 -- 2014/07/09 ADD END
     ,ov_errbuf                      => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode                     => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                      => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���̋@������񒊏o����(A-2)�A���̋@����CSV�o�͏���(A-3)
    -- ===============================
    output_csv(
      ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- 
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE no_data_warn_expt;
    END IF;
--
  EXCEPTION
    -- �Ώۃf�[�^�Ȃ��x��
    WHEN no_data_warn_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                          OUT VARCHAR2     -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                         OUT VARCHAR2     -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_search_type                  IN  VARCHAR2     -- 1.�����敪 
   ,iv_machine_type                 IN  VARCHAR2     -- 2.�@��敪
   ,iv_object_code                  IN  VARCHAR2     -- 3.�����R�[�h
   ,iv_object_status                IN  VARCHAR2     -- 4.�����X�e�[�^�X
   ,iv_department_code              IN  VARCHAR2     -- 5.�Ǘ�����
   ,iv_manufacturer_name            IN  VARCHAR2     -- 6.���[�J��
   ,iv_model                        IN  VARCHAR2     -- 7.�@��
   ,iv_dclr_place                   IN  VARCHAR2     -- 8.�\���n
   ,iv_date_placed_in_service_from  IN  VARCHAR2     -- 9.���Ƌ��p�� FROM
   ,iv_date_placed_in_service_to    IN  VARCHAR2     -- 10.���Ƌ��p�� TO
   ,iv_date_retired_from            IN  VARCHAR2     -- 11.�����p�� FROM
   ,iv_date_retired_to              IN  VARCHAR2     -- 12.�����p�� TO
   ,iv_process_type                 IN  VARCHAR2     -- 13.���������敪
   ,iv_process_date_from            IN  VARCHAR2     -- 14.���������� FROM
   ,iv_process_date_to              IN  VARCHAR2     -- 15.���������� TO
 -- 2014/07/09 ADD START
   ,iv_vendor_code                  IN  VARCHAR2     -- 16.�d����R�[�h
 -- 2014/07/09 ADD END
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_search_type                 => iv_search_type                 -- 1.�����敪 
      ,iv_machine_type                => iv_machine_type                -- 2.�@��敪
      ,iv_object_code                 => iv_object_code                 -- 3.�����R�[�h
      ,iv_object_status               => iv_object_status               -- 4.�����X�e�[�^�X
      ,iv_department_code             => iv_department_code             -- 5.�Ǘ�����
      ,iv_manufacturer_name           => iv_manufacturer_name           -- 6.���[�J��
      ,iv_model                       => iv_model                       -- 7.�@��
      ,iv_dclr_place                  => iv_dclr_place                  -- 8.�\���n
      ,iv_date_placed_in_service_from => TO_DATE(iv_date_placed_in_service_from,cv_format_std) -- 9.���Ƌ��p�� FROM
      ,iv_date_placed_in_service_to   => TO_DATE(iv_date_placed_in_service_to,cv_format_std)   -- 10.���Ƌ��p�� TO
      ,iv_date_retired_from           => TO_DATE(iv_date_retired_from,cv_format_std)           -- 11.�����p�� FROM
      ,iv_date_retired_to             => TO_DATE(iv_date_retired_to,cv_format_std)             -- 12.�����p�� TO
      ,iv_process_type                => iv_process_type                -- 13.���������敪
      ,iv_process_date_from           => TO_DATE(iv_process_date_from,cv_format_std)           -- 14.���������� FROM
      ,iv_process_date_to             => TO_DATE(iv_process_date_to,cv_format_std)             -- 15.���������� TO
 -- 2014/07/09 ADD START
      ,iv_vendor_code                 => iv_vendor_code                 -- 16.�d����R�[�h
 -- 2014/07/09 ADD END
      ,ov_errbuf                      => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode                     => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                      => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- �Ώی����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- ���������o��
    --==================================================
    IF( lv_retcode = cv_status_error )
    THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- �G���[�����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal)
    THEN
      lv_message_code := cv_msg_cff_90004;
    ELSIF(lv_retcode = cv_status_warn)
    THEN
      lv_message_code := cv_msg_cff_90005;
    ELSIF(lv_retcode = cv_status_error)
    THEN
      lv_message_code := cv_msg_cff_90006;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error)
    THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFF017A02C;
/
