CREATE OR REPLACE PACKAGE BODY xxwsh620003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620003c(body)
 * Description      : ���Ɉ˗��\
 * MD.050           : ����/�z��(���[) T_MD050_BPO_620
 * MD.070           : ���Ɉ˗��\ T_MD070_BPO_62D
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_initialize         PROCEDURE : ��������
 *  prc_get_report_data    PROCEDURE : ���[�f�[�^�擾����
 *  prc_create_xml_data    PROCEDURE : XML��������
 *  fnc_convert_into_xml   FUNCTION  : XML�f�[�^�ϊ�
 *  submain                PROCEDURE : ���C�������v���V�[�W��
 *  main                   PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/13    1.0   Nozomi Kashiwagi �V�K�쐬
 *  2008/06/04    1.1   Jun Nakada       �m�菈�������{(�ʒm����=NULL)�̏ꍇ�̏o�͐���
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���������ʗ�O ***
  no_data_expt       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                CONSTANT  VARCHAR2(100) := 'xxwsh620003c' ;     -- �p�b�P�[�W��
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620003T' ;      -- ���[ID
  -- ���[�^�C�g��
  gc_report_title_plan       CONSTANT  VARCHAR2(10) := '���ɗ\��\' ;        -- ���ɗ\��\
  gc_report_title_decide     CONSTANT  VARCHAR2(10) := '���Ɉ˗��\' ;        -- ���Ɉ˗��\
  -- �ړ��^�C�v
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;                 -- �ϑ��Ȃ�
  -- �ړ��X�e�[�^�X
  gc_status_reqed            CONSTANT  VARCHAR2(2)  := '02' ;                -- �˗���
  gc_status_not              CONSTANT  VARCHAR2(2)  := '99' ;                -- ���
  -- �����^�C�v
  gc_doc_type_code_mv        CONSTANT  VARCHAR2(2)  := '20' ;                -- �ړ�
  -- ���R�[�h�^�C�v
  gc_rec_type_code_ins       CONSTANT  VARCHAR2(2)  := '10' ;                -- �w��
  -- �\��m��敪
  gc_plan_decide_p           CONSTANT  VARCHAR2(1)  := '1' ;                 -- �\��
  gc_plan_decide_d           CONSTANT  VARCHAR2(1)  := '2' ;                 -- �m��
  -- �ʒm�X�e�[�^�X
  gc_notif_status_notify     CONSTANT  VARCHAR2(2)  := '10' ;                -- ���ʒm
  gc_notif_status_not_notify CONSTANT  VARCHAR2(2)  := '20' ;                -- �Ēʒm�v
  gc_notif_status_notified   CONSTANT  VARCHAR2(2)  := '40' ;                -- �m��ʒm��
  -- ���[�U�[�敪
  gc_user_kbn_inside         CONSTANT  VARCHAR2(1)  := '1' ;                 -- ����
  gc_user_kbn_outside        CONSTANT  VARCHAR2(1)  := '2' ;                 -- �O��
  -- ���i�敪
  gc_prod_cd_drink           CONSTANT  VARCHAR2(1)  := '2' ;                 -- �h�����N
  gc_item_cd_prdct           CONSTANT  VARCHAR2(1)  := '5' ;                 -- ���i
  gc_item_cd_material        CONSTANT  VARCHAR2(1)  := '1' ;                 -- ����
  gc_item_cd_prdct_half      CONSTANT  VARCHAR2(1)  := '4' ;                 -- �����i
  gc_item_cd_shizai          CONSTANT  VARCHAR2(1)  := '2' ;                 -- ����
  -- ���b�g�Ǘ�
  gc_lot_ctl_manage          CONSTANT  VARCHAR2(1)  := '1' ;                 -- ���b�g�Ǘ�����Ă���
  -- ���t�t�H�[�}�b�g
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �N���������b
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- �N����
  gc_date_fmt_hh24mi         CONSTANT  VARCHAR2(10) := 'HH24:MI' ;               -- ����
  gc_date_fmt_ymd_ja         CONSTANT  VARCHAR2(20) := 'YYYY"�N"MM"��"DD"��' ;   -- ����
  -- ���t
  gc_date_start              CONSTANT  VARCHAR2(10) := '1900/01/01' ;
  gc_date_end                CONSTANT  VARCHAR2(10) := '9999/12/31' ;
  -- ����
  gc_time_start              CONSTANT  VARCHAR2(5) := '00:00' ;
  gc_time_end                CONSTANT  VARCHAR2(5) := '23:59' ;
  -- ADD START 2008/06/04
  gc_time_ss_start           CONSTANT  VARCHAR2(3) := '00' ;
  gc_time_ss_end             CONSTANT  VARCHAR2(3) := '59' ;
  -- ADD END 2008/06/04
  -- �o�̓^�O
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- �O���[�v�^�O
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- �f�[�^�^�O
  -- �V�K�C���t���O
  gc_new_modify_flg_mod      CONSTANT  VARCHAR2(1)  := 'M' ;                 -- �C��
  gc_asterisk                CONSTANT  VARCHAR2(1)  := '*' ;                 -- �Œ�l�u*�v
  ------------------------------
  -- �v���t�@�C���֘A
  ------------------------------
  gc_prof_name_item_div      CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_DIV_SECURITY' ; -- ���i�敪
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  --�A�v���P�[�V������
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;             -- ��޵�:�o�ץ������z��
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;             -- ��޵�:�o�ץ������z��
  --���b�Z�[�WID
  gc_msg_id_required         CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12102' ;   -- ���Ұ������ʹװ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;   -- ���[0���G���[
  gc_msg_id_not_get_prof     CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12301' ;   -- ���̧�َ擾�װ
  gc_msg_id_prm_chk          CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12256' ;   -- ���Ұ������װ
  --���b�Z�[�W-�g�[�N����
  gc_msg_tkn_nm_parmeta      CONSTANT  VARCHAR2(10) := 'PARMETA' ;           -- �p�����[�^��
  gc_msg_tkn_nm_prof         CONSTANT  VARCHAR2(10) := 'PROF_NAME' ;         -- �v���t�@�C����
  --���b�Z�[�W-�g�[�N���l
  gc_msg_tkn_val_parmeta     CONSTANT  VARCHAR2(20) := '�m��ʒm���{��' ;
  gc_msg_tkn_val_prof_prod   CONSTANT  VARCHAR2(30) := 'XXCMN�F���i�敪(�Z�L�����e�B)' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  ------------------------------
  -- ���̓p�����[�^�֘A
  ------------------------------
  -- ���̓p�����[�^�i�[�p���R�[�h
  TYPE rec_param_data IS RECORD(
     dept                  VARCHAR2(10)    -- 01:����
    ,plan_decide_kbn       VARCHAR2(1)     -- 02:�\��/�m��敪
    ,ship_from             DATE            -- 03:�o�ɓ�From
    ,ship_to               DATE            -- 04:�o�ɓ�To
  -- MOD START 2008/06/04 NAKADA �^�̕ύX(DATE >> VARCHAR2)
    ,notif_date            VARCHAR2(10)    -- 05:�m��ʒm���{��
  -- MOD END   2008/06/04 NAKADA
    ,notif_time_from       VARCHAR2(5)     -- 06:�m��ʒm���{����From
    ,notif_time_to         VARCHAR2(5)     -- 07:�m��ʒm���{����To
    ,block1                VARCHAR2(5)     -- 08:�u���b�N1
    ,block2                VARCHAR2(5)     -- 09:�u���b�N2
    ,block3                VARCHAR2(5)     -- 10:�u���b�N3
    ,ship_to_locat_code    VARCHAR2(4)     -- 11:���ɐ�
    ,shipped_locat_code    VARCHAR2(4)     -- 12:�o�Ɍ�
    ,freight_carrier_code  VARCHAR2(4)     -- 13:�^���Ǝ�
    ,delivery_no           VARCHAR2(12)    -- 14:�z��No
    ,mov_num               VARCHAR2(12)    -- 15:�ړ�No
    ,online_kbn            VARCHAR2(1)     -- 16:�I�����C���Ώۋ敪
    ,item_kbn              VARCHAR2(1)     -- 17:�i�ڋ敪
    ,arrival_date_from     DATE            -- 18:����From
    ,arrival_date_to       DATE            -- 19:����To
  );
  type_rec_param_data   rec_param_data ;
--
  ------------------------------
  -- �o�̓f�[�^�֘A
  ------------------------------
  -- ���R�[�h�錾�p
  xcs     xxwsh_carriers_schedule%ROWTYPE ;          -- �z�Ԕz���v��(�A�h�I��)
  xmrih   xxinv_mov_req_instr_headers%ROWTYPE ;      -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
  xmril   xxinv_mov_req_instr_lines%ROWTYPE ;        -- �ړ��˗�/�w�����ׁi�A�h�I���j
  xmld    xxinv_mov_lot_details%ROWTYPE ;            -- �ړ����b�g�ڍ�(�A�h�I��)
  xilv1   xxcmn_item_locations2_v%ROWTYPE ;          -- OPM�ۊǏꏊ���VIEW(��)
  xilv2   xxcmn_item_locations2_v%ROWTYPE ;          -- OPM�ۊǏꏊ���VIEW(�o)
  xcv     xxcmn_carriers2_v%ROWTYPE ;                -- �^���Ǝҏ��VIEW
  ximv    xxcmn_item_mst2_v%ROWTYPE ;                -- OPM�i�ڏ��VIEW2
  ilm     ic_lots_mst%ROWTYPE ;                      -- OPM���b�g�}�X�^
  xicv4   xxcmn_item_categories4_v%ROWTYPE ;         -- OPM�i�ڃJ�e�S���������VIEW4
  xsmv    xxwsh_ship_method2_v%ROWTYPE ;             -- �z���敪���VIEW2
--
  -- �o�̓f�[�^�i�[�p���R�[�h
  TYPE rec_report_data IS RECORD(
     ship_to_locat_code     xmrih.ship_to_locat_code%TYPE     -- ���ɐ�(�R�[�h)
    ,ship_to_locat_name     xilv1.description%TYPE            -- ���ɐ於��
    ,schedule_arrival_date  xmrih.schedule_arrival_date%TYPE  -- ����
    ,item_class_name        xicv4.item_class_name%TYPE        -- �i�ڋ敪
    ,new_modify_flg         xmrih.new_modify_flg%TYPE         -- �V�K�C���t���O
    ,schedule_ship_date     xmrih.schedule_ship_date%TYPE     -- �o�ɓ�
    ,delivery_no            xmrih.delivery_no%TYPE            -- �z��No
    ,shipping_method_code   xmrih.shipping_method_code%TYPE   -- �z���敪
    ,shipping_method_name   xsmv.ship_method_meaning%TYPE     -- �z���敪�i���́j
    ,career_id              xmrih.career_id%TYPE              -- �^���Ǝ�
    ,career_name            xcv.party_name%TYPE               -- �^���ƎҖ���
    ,shipped_locat_code     xmrih.shipped_locat_code%TYPE     -- �o�Ɍ�
    ,shipped_locat_name     xilv2.description%TYPE            -- �o�Ɍ�(����)
    ,prev_delivery_no       xmrih.prev_delivery_no%TYPE       -- �O��z��No
    ,mov_num                xmrih.mov_num%TYPE                -- �ړ�No
    ,arrival_time_from      xmrih.arrival_time_from%TYPE      -- ���׎���From
    ,arrival_time_to        xmrih.arrival_time_to%TYPE        -- ���׎���To
    ,description            xmrih.description%TYPE            -- �E�v
    ,batch_no               xmrih.batch_no%TYPE               -- ��zNo
    ,item_code              xmril.item_code%TYPE              -- �i��(�R�[�h)
    ,item_name              ximv.item_desc1%TYPE              -- �i��(����)
    ,net                    ximv.net%TYPE                     -- �d��(NET)
    ,lot_no                 xmld.lot_no%TYPE                  -- ���b�gNo
    ,prodct_date            ilm.attribute1%TYPE               -- ������
    ,best_before_date       ilm.attribute3%TYPE               -- �ܖ�����
    ,uniqe_sign             ilm.attribute2%TYPE               -- �ŗL�L��
    ,num_qty                NUMBER                            -- ����
    ,quantity               NUMBER                            -- ����
    ,conv_unit              VARCHAR2(3)                       -- ���o�Ɋ��Z�P��
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_param              rec_param_data ;      -- ���̓p�����[�^���
  gt_report_data        list_report_data ;    -- �o�̓f�[�^
  gt_xml_data_table     XML_DATA ;            -- XML�f�[�^
  gv_report_title       VARCHAR2(20) ;        -- ���[�^�C�g��
  gv_dept_cd            VARCHAR2(10) ;        -- �S������
  gv_dept_nm            VARCHAR2(14) ;        -- �S����
  gv_uom_weight         VARCHAR2(3);          -- �o�׏d�ʒP��
  gv_uom_capacity       VARCHAR2(3);          -- �o�חe�ϒP��
  gv_prod_kbn           VARCHAR2(1);          -- ���i�敪
  gd_common_sysdate     DATE;                 -- �V�X�e�����t
  gd_notif_date_from    DATE;                 -- �m��u���b�N���{����_FROM
  gd_notif_date_to      DATE;                 -- �m��u���b�N���{����_TO
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE prc_initialize(
    ov_errbuf     OUT  VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_initialize' ;  -- �v���O������
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
    -- *** ���[�J���E��O���� ***
    prm_check_expt     EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
    get_prof_expt      EXCEPTION ;     -- �v���t�@�C���擾��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- �ϐ������ݒ�
    -- ===============================================
    gd_common_sysdate := SYSDATE ;    -- �V�X�e�����t
--
    -- ====================================================
    -- �p�����[�^�`�F�b�N
    -- ====================================================
    -- �\��/�m��敪�`�F�b�N
    IF (gt_param.plan_decide_kbn = gc_plan_decide_d) THEN
      IF (gt_param.notif_date IS NULL) THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                              ,gc_msg_id_required
                                              ,gc_msg_tkn_nm_parmeta
                                              ,gc_msg_tkn_val_parmeta
                                             ) ;
        RAISE prm_check_expt ;
      END IF ;
    END IF ;
--
    -- �m��ʒm���{���A�m��ʒm���{���ԃ`�F�b�N
    IF ((gt_param.notif_date IS NULL)
      AND ((gt_param.notif_time_from IS NOT NULL) OR (gt_param.notif_time_to IS NOT NULL))) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh, gc_msg_id_prm_chk ) ;
      RAISE prm_check_expt ;
    END IF;
--
    -- ====================================================
    -- �v���t�@�C���l�擾
    -- ====================================================
    -- �E�ӁF���i�敪(�Z�L�����e�B)�擾
    gv_prod_kbn := FND_PROFILE.VALUE(gc_prof_name_item_div) ;
    IF (gv_prod_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- ADD START 2008/06/04 NAKADA
    -- �m��ʒm���{���A�m��ʒm���{���Ԃ̕ҏW
    gd_notif_date_from
      := TO_DATE(NVL(gt_param.notif_date, gc_date_start)
                 || ' '
                 || NVL(gt_param.notif_time_from, gc_time_start)
                 || ':'
                 || gc_time_ss_start
                , gc_date_fmt_all);
    gd_notif_date_to
      := TO_DATE(NVL(gt_param.notif_date, gc_date_end)
                 || ' '
                 || NVL(gt_param.notif_time_to, gc_time_end)
                 || ':'
                 || gc_time_ss_end
                , gc_date_fmt_all);
    -- ADD END 2008/06/04 NAKADA
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O�n���h�� ***
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
    --*** �v���t�@�C���擾��O�n���h�� ***
    WHEN get_prof_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���[�f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
    ov_errbuf      OUT   VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT   VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT   VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ;  -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_main_data
    IS
      SELECT
             xmrih.ship_to_locat_code      AS  ship_to_locat_code        -- ���ɐ�(�R�[�h)
            ,xilv1.description             AS  description_in            -- ���ɐ於��
            ,xmrih.schedule_arrival_date   AS  schedule_arrival_date     -- ����
            ,xicv4.item_class_name         AS  item_class_name           -- �i�ڋ敪
            ,CASE
              WHEN (xmrih.new_modify_flg = gc_new_modify_flg_mod)
                THEN gc_asterisk
              ELSE  NULL
             END                           AS  new_modify_flg            -- �V�K�C���t���O
            ,xmrih.schedule_ship_date      AS  schedule_ship_date        -- �o�ɓ�
            ,xmrih.delivery_no             AS  delivery_no               -- �z��No
            ,xmrih.shipping_method_code    AS  shipping_method_code      -- �z���敪
            ,xsmv.ship_method_meaning      AS  shipping_method_name      -- �z���敪(����)
            ,xmrih.career_id               AS  career_id                 -- �^���Ǝ�
            ,xcv.party_name                AS  career_name               -- �^���ƎҖ���
            ,xmrih.shipped_locat_code      AS  shipped_locat_code        -- �o�Ɍ�
            ,xilv2.description             AS  description_out           -- �o�Ɍ�(����)
            ,xmrih.prev_delivery_no        AS  prev_delivery_no          -- �O��z��No
            ,xmrih.mov_num                 AS  mov_num                   -- �ړ�No
            ,xmrih.arrival_time_from       AS  arrival_time_from         -- ���׎���From
            ,xmrih.arrival_time_to         AS  arrival_time_to           -- ���׎���To
            ,xmrih.description             AS  description               -- �E�v
            ,xmrih.batch_no                AS  batch_no                  -- ��zNo
            ,xmril.item_code               AS  item_code                 -- �i��(�R�[�h)
            ,ximv.item_short_name          AS  item_name                 -- �i��(����)
            ,ximv.net                      AS  net                       -- NET
            ,CASE
              WHEN (xmril.reserved_quantity IS NOT NULL) THEN xmld.lot_no
              ELSE NULL
             END                           AS  lot_no                    -- ���b�gNo
            ,ilm.attribute1                AS  prodct_date               -- ������
            ,ilm.attribute3                AS  best_before_date          -- �ܖ�����
            ,ilm.attribute2                AS  uniqe_sign                -- �ŗL�L��
            ,CASE
              -- ���i�̏ꍇ
              WHEN ((xicv4.item_class_code = gc_item_cd_prdct) 
                AND (ximv.lot_ctl = gc_lot_ctl_manage)
                AND (ilm.attribute6 IS NOT NULL)
              ) THEN ximv.num_of_cases
              -- ���̑��̕i�ڂ̏ꍇ
              WHEN (((xicv4.item_class_code = gc_item_cd_material) 
                OR  (xicv4.item_class_code = gc_item_cd_prdct_half))
                AND (ximv.lot_ctl = gc_lot_ctl_manage)
                AND (ilm.attribute6 IS NOT NULL)
              ) THEN ilm.attribute6
              -- �݌ɓ������ݒ肳��Ă��Ȃ�,���ޑ�,���b�g�Ǘ����Ă��Ȃ��ꍇ
              WHEN ((xicv4.item_class_code = gc_item_cd_shizai)
                OR  (ilm.attribute6 IS NULL)
                OR  (ximv.lot_ctl <> gc_lot_ctl_manage)
              ) THEN ximv.frequent_qty
             END                           AS  num_qty                   -- ����
            ,CASE
               -- ��������Ă���ꍇ
               WHEN (xmril.reserved_quantity IS NOT NULL) THEN (
                 CASE 
                  WHEN ( xicv4.prod_class_code = gc_prod_cd_drink
                     AND xicv4.item_class_code = gc_item_cd_prdct
                     AND ximv.conv_unit IS NOT NULL
                  ) THEN (xmld.actual_quantity / TO_NUMBER(
                                                   CASE WHEN ximv.num_of_cases > 0 
                                                          THEN  ximv.num_of_cases
                                                        ELSE TO_CHAR(1)
                                                   END)
                         )
                  ELSE xmld.actual_quantity
                 END
               )
               -- ��������Ă��Ȃ��ꍇ
               WHEN ((xmril.reserved_quantity IS NULL) OR (xmril.reserved_quantity = 0)) THEN (
                 CASE 
                  WHEN ( xicv4.prod_class_code = gc_prod_cd_drink
                     AND xicv4.item_class_code = gc_item_cd_prdct
                     AND ximv.conv_unit IS NOT NULL
                  ) THEN (xmril.instruct_qty / TO_NUMBER(
                                                   CASE WHEN ximv.num_of_cases > 0 
                                                          THEN  ximv.num_of_cases
                                                        ELSE TO_CHAR(1)
                                                   END)
                         )
                  ELSE xmril.instruct_qty
                 END
               )
             END                           AS  quantity                  --����
            ,CASE 
              WHEN ( xicv4.prod_class_code = gc_prod_cd_drink
                 AND xicv4.item_class_code = gc_item_cd_prdct
                 AND ximv.conv_unit IS NOT NULL
              ) THEN ximv.conv_unit
              ELSE ximv.item_um
             END                           AS  conv_unit                 --���o�Ɋ��Z�P��
      FROM
             xxwsh_carriers_schedule        xcs       -- �z�Ԕz���v��(�A�h�I��)
            ,xxinv_mov_req_instr_headers    xmrih     -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            ,xxinv_mov_req_instr_lines      xmril     -- �ړ��˗�/�w�����ׁi�A�h�I���j
            ,xxinv_mov_lot_details          xmld      -- �ړ����b�g�ڍ�(�A�h�I��)
            ,xxcmn_item_locations2_v        xilv1     -- OPM�ۊǏꏊ���VIEW(��)
            ,xxcmn_item_locations2_v        xilv2     -- OPM�ۊǏꏊ���VIEW(�o)
            ,xxcmn_carriers2_v              xcv       -- �^���Ǝҏ��VIEW
            ,xxcmn_item_mst2_v              ximv      -- OPM�i�ڏ��VIEW2
            ,ic_lots_mst                    ilm       -- OPM���b�g�}�X�^
            ,xxcmn_item_categories4_v       xicv4     -- OPM�i�ڃJ�e�S���������VIEW4
            ,fnd_user                       fu        -- ���[�U�[�}�X�^
            ,per_all_people_f               papf      -- �]�ƈ��}�X�^
            ,xxwsh_ship_method2_v           xsmv      -- �z���敪���VIEW2
      WHERE
        ----------------------------------------------------------------------------------
        -- �w�b�_���
             xmrih.mov_num               =  NVL(gt_param.mov_num, xmrih.mov_num)
        AND  xmrih.delivery_no           =  xcs.delivery_no(+)
        AND  (gt_param.delivery_no IS NULL
          OR  xmrih.delivery_no = gt_param.delivery_no
        )
        AND  xmrih.mov_type             <>  gc_mov_type_not_ship
        AND  xmrih.status               >=  gc_status_reqed
        AND  xmrih.status               <>  gc_status_not
        AND  (gt_param.dept IS NULL
          OR  xmrih.instruction_post_code = gt_param.dept
        )
        ----------------------------------------------------------------------------------
        -- �o�ɓ�From�`To�A����From�`To
        AND  xmrih.schedule_ship_date  >= gt_param.ship_from
        AND  (gt_param.ship_to IS NULL
          OR  xmrih.schedule_ship_date <= gt_param.ship_to
        )
        AND  (gt_param.arrival_date_from IS NULL
          OR  xmrih.schedule_arrival_date >= gt_param.arrival_date_from
        )
        AND  (gt_param.arrival_date_to IS NULL
          OR  xmrih.schedule_arrival_date <= gt_param.arrival_date_to
        )
        ----------------------------------------------------------------------------------
        -- ���ɐ���
        AND  xmrih.ship_to_locat_id      =  xilv1.inventory_location_id
        AND  ( (gt_param.online_kbn IS NULL)
            OR (xilv1.eos_control_type = gt_param.online_kbn)
        )
        AND  (
              (xilv1.distribution_block = gt_param.block1)
          OR  (xilv1.distribution_block = gt_param.block2)
          OR  (xilv1.distribution_block = gt_param.block3)
          OR  (xmrih.ship_to_locat_code = gt_param.ship_to_locat_code)
          OR  ((gt_param.block1 IS NULL) AND (gt_param.block2 IS NULL) AND (gt_param.block3 IS NULL)
           AND (gt_param.ship_to_locat_code IS NULL)
          )
        )
        ----------------------------------------------------------------------------------
        -- �o�Ɍ����
        AND  xmrih.shipped_locat_id    =  xilv2.inventory_location_id
        AND  ((gt_param.shipped_locat_code IS NULL)
            OR (xmrih.shipped_locat_code = gt_param.shipped_locat_code)
        )
        ----------------------------------------------------------------------------------
        -- �^���Ǝҏ��
        AND  ((gt_param.freight_carrier_code IS NULL)
            OR (xmrih.freight_carrier_code = gt_param.freight_carrier_code)
        )
        AND  xmrih.career_id        =  xcv.party_id(+)
        AND  (xcv.party_id IS NULL
          OR (xcv.start_date_active <= xmrih.schedule_ship_date
            AND  (xcv.end_date_active >= xmrih.schedule_ship_date
              OR  xcv.end_date_active IS NULL
            )
          )
        )
        ----------------------------------------------------------------------------------
        -- �m��ʒm���{��
        -- MOD START 2008/06/04 NAKADA   �p�����[�^���{�������͂Ŏ��{���������ݒ�̏ꍇ���o��
        --                               ���̑��̏ꍇ�ɂ́A�p�����[�^�̓��͏����ɏ]���Ē��o�B
        AND  ((gt_param.notif_date IS NULL AND
               xmrih.notif_date IS NULL)
               OR
              (xmrih.notif_date >= gd_notif_date_from AND
               xmrih.notif_date >= gd_notif_date_from)
        )
        -- MOD END   2008/06/04 NAKADA
        ----------------------------------------------------------------------------------
        -- ���׏��
        AND  xmrih.mov_hdr_id         =  xmril.mov_hdr_id
        AND  xmril.item_id            =  ximv.item_id
        AND  ximv.start_date_active  <=  xmrih.schedule_ship_date
        AND (ximv.end_date_active    >=  xmrih.schedule_ship_date
          OR ximv.end_date_active IS NULL
        )
        ----------------------------------------------------------------------------------
        -- OPM�i�ڃJ�e�S���������
        AND  ximv.item_id                =  xicv4.item_id
        AND  (gt_param.item_kbn IS NULL
          OR  xicv4.item_class_code = gt_param.item_kbn
        )
        AND  xicv4.prod_class_code = gv_prod_kbn
        ----------------------------------------------------------------------------------
        -- �ړ����b�g�ڍ׏��
        AND  xmril.mov_line_id           =  xmld.mov_line_id(+)
        AND  xmld.document_type_code(+)  =  gc_doc_type_code_mv
        AND  xmld.record_type_code(+)    =  gc_rec_type_code_ins
        AND  xmld.lot_id                 =  ilm.lot_id(+)
        AND  xmld.item_id                =  ilm.item_id(+)
        ----------------------------------------------------------------------------------
        -- �z���敪���
        AND  xsmv.ship_method_code       =  xmrih.shipping_method_code
        ----------------------------------------------------------------------------------
        -- �\��m��敪
        AND  (
              -- �\��̏ꍇ
              ((gt_param.plan_decide_kbn = gc_plan_decide_p)
                AND  (xmrih.notif_status = gc_notif_status_notify
                  OR  xmrih.notif_status = gc_notif_status_not_notify)
              )
              -- �m��̏ꍇ
          OR  ((gt_param.plan_decide_kbn = gc_plan_decide_d)
                AND  (xmrih.notif_status = gc_notif_status_notified)
              )
        )
        ----------------------------------------------------------------------------------
        -- ���[�U�[���̒��o
        AND  fu.user_id                  =  FND_GLOBAL.USER_ID
        AND  papf.person_id            =  fu.employee_id
        AND  (
              -- �������[�U�[�̏ꍇ
              (papf.attribute3  = gc_user_kbn_inside)
              -- �O�����[�U�[�̏ꍇ
          OR  ((papf.attribute3 = gc_user_kbn_outside)
                AND (
                      -- �q�ɋƎ҂̏ꍇ
                      (((papf.attribute4 IS NOT NULL) AND (papf.attribute5 IS NULL))
                        AND ( xilv1.purchase_code = papf.attribute4 
                          OR  xilv2.purchase_code = papf.attribute4)
                      )
                      -- �q�Ɍ��^���Ǝ҂̏ꍇ
                  OR  (((papf.attribute4 IS NOT NULL)  AND  (papf.attribute5 IS NOT NULL))
                        AND ( xmrih.freight_carrier_code = papf.attribute5
                          OR  xilv1.purchase_code        = papf.attribute4
                          OR  xilv2.purchase_code        = papf.attribute4)
                      )
                      -- �^���Ǝ҂̏ꍇ
                  OR  (((papf.attribute4 IS NULL) AND (papf.attribute5 IS NOT NULL))
                        AND  xmrih.freight_carrier_code = papf.attribute5
                      )
                )
          )
        )
      ORDER BY
             ship_to_locat_code     ASC   -- ���ɐ�
            ,schedule_arrival_date  ASC   -- ���ɗ\���
            ,shipped_locat_code     ASC   -- �o�Ɍ�
            ,schedule_ship_date     ASC   -- �o�ɗ\���
            ,delivery_no            ASC   -- �z��No
            ,mov_num                ASC   -- �ړ��ԍ�
            ,item_code              ASC   -- �i�ڃR�[�h
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- ���[�^�C�g������
    -- ====================================================
    -- �\��/�m��敪���u�\��v�̏ꍇ
    IF (gt_param.plan_decide_kbn = gc_plan_decide_p) THEN
      gv_report_title := gc_report_title_plan;
--
    -- �\��/�m��敪���u�m��v�̏ꍇ
    ELSE
      gv_report_title := gc_report_title_decide;
    END IF ;
--
    -- ====================================================
    -- �S���ҏ��擾
    -- ====================================================
    -- �S������
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10) ;
    -- �S����
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14) ;
--
    -- ====================================================
    -- ���[�f�[�^�擾
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_main_data ;
    -- �o���N�t�F�b�`
    FETCH cur_main_data BULK COLLECT INTO gt_report_data ;
    -- �J�[�\���N���[�Y
    CLOSE cur_main_data ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML��������
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
    ov_errbuf     OUT  VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ;   -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- �O�񃌃R�[�h�i�[�p
    lv_tmp_nyuko_cd             type_report_data.ship_to_locat_code%TYPE ;    -- ���ɐ�R�[�h�����
    lv_tmp_nyuko_date           type_report_data.schedule_arrival_date%TYPE ; -- ���ɗ\��������
    lv_tmp_delivery_no          type_report_data.delivery_no%TYPE ;           -- �z��No�����
    lv_tmp_move_no              type_report_data.mov_num%TYPE ;               -- �ړ�No�����
    lv_tmp_item_code            type_report_data.item_code%TYPE ;             -- �i�ڃR�[�h�����
    -- �^�O�o�͔���t���O
    lb_dispflg_nyuko_cd         BOOLEAN := TRUE ;       -- ���ɐ�R�[�h�����
    lb_dispflg_nyuko_date       BOOLEAN := TRUE ;       -- ���ɗ\��������
    lb_dispflg_delivery_no      BOOLEAN := TRUE ;       -- �z��No�����
    lb_dispflg_move_no          BOOLEAN := TRUE ;       -- �ړ�No�����
    lb_dispflg_item_code        BOOLEAN := TRUE ;       -- �i�ڃR�[�h�����
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : �^�O���ݒ菈��
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2                 -- �^�O��
      ,ivsub_tag_value      IN  VARCHAR2                 -- �f�[�^
      ,ivsub_tag_type       IN  VARCHAR2  DEFAULT NULL   -- �f�[�^
    )IS
      ln_data_index  NUMBER ;    -- XML�f�[�^��ݒ肷��C���f�b�N�X
    BEGIN
      ln_data_index := gt_xml_data_table.COUNT + 1 ;
      
      gt_xml_data_table(ln_data_index).tag_name := ivsub_tag_name ;
      
      IF ((ivsub_tag_value IS NULL) AND (ivsub_tag_type = gc_tag_type_tag)) THEN
        -- �^�O�o��
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
      ELSE
        -- �f�[�^�o��
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
        gt_xml_data_table(ln_data_index).tag_value := ivsub_tag_value;
      END IF;
    END prcsub_set_xml_data ;
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : �^�O���ݒ菈��(�J�n�E�I���^�O�p)
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2  -- �^�O��
    )IS
    BEGIN
      prcsub_set_xml_data(ivsub_tag_name, NULL, gc_tag_type_tag);
    END prcsub_set_xml_data ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- -----------------------------------------------------
    -- �ϐ������ݒ�
    -- -----------------------------------------------------
    gt_xml_data_table.DELETE ;
    lv_tmp_nyuko_cd    := NULL ;
    lv_tmp_nyuko_date  := NULL ;
    lv_tmp_delivery_no := NULL ;
    lv_tmp_move_no     := NULL ;
    lv_tmp_item_code   := NULL ;
--
    -- -----------------------------------------------------
    -- �w�b�_���ݒ�
    -- -----------------------------------------------------
    prcsub_set_xml_data('root') ;
    prcsub_set_xml_data('data_info') ;
    prcsub_set_xml_data('lg_nyuko_info') ;
--
    -- -----------------------------------------------------
    -- ���[0���pXML�f�[�^�쐬
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn, gc_msg_id_no_data ) ;
--
      prcsub_set_xml_data('g_nyuko_info') ;
      prcsub_set_xml_data('head_title' , gv_report_title) ;
      prcsub_set_xml_data('lg_nyuko_yotei_info') ;
      prcsub_set_xml_data('g_nyuko_yotei_info') ;
      prcsub_set_xml_data('msg' , ov_errmsg) ;
      prcsub_set_xml_data('/g_nyuko_yotei_info') ;
      prcsub_set_xml_data('/lg_nyuko_yotei_info') ;
      prcsub_set_xml_data('/g_nyuko_info');
    END IF ;
--
    -- -----------------------------------------------------
    -- XML�f�[�^�쐬
    -- -----------------------------------------------------
    <<detail_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XML�f�[�^�ݒ�
      -- ====================================================
      -- �w�b�_��(���ɐ�R�[�h���)
      IF (lb_dispflg_nyuko_cd) THEN
        prcsub_set_xml_data('g_nyuko_info') ;
        prcsub_set_xml_data('head_title'       , gv_report_title) ;
        prcsub_set_xml_data('chohyo_id'        , gc_report_id) ;
        prcsub_set_xml_data('exec_time'        , TO_CHAR(gd_common_sysdate, gc_date_fmt_all)) ;
        prcsub_set_xml_data('dep_cd'           , gv_dept_cd) ;
        prcsub_set_xml_data('dep_nm'           , gv_dept_nm) ;
        prcsub_set_xml_data('chakubi_from'
          , TO_CHAR(gt_param.arrival_date_from, gc_date_fmt_ymd_ja)) ;
        prcsub_set_xml_data('chakubi_to'
          , TO_CHAR(gt_param.arrival_date_to, gc_date_fmt_ymd_ja)) ;
        prcsub_set_xml_data('nyuko_cd'         , gt_report_data(i).ship_to_locat_code) ;
        prcsub_set_xml_data('nyuko_nm'         , gt_report_data(i).ship_to_locat_name) ;
        prcsub_set_xml_data('lg_nyuko_yotei_info') ;
      END IF ;
--
      -- �w�b�_��(���ɗ\������)
      IF (lb_dispflg_nyuko_date) THEN
        prcsub_set_xml_data('g_nyuko_yotei_info') ;
        prcsub_set_xml_data('chakubi'
          , TO_CHAR(gt_report_data(i).schedule_arrival_date, gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('item_kbn'
          , gt_param.item_kbn) ;
        prcsub_set_xml_data('lg_delivery_info') ;
      END IF ;
--
      -- ���ו�(�z��No���)
      IF (lb_dispflg_delivery_no) THEN
        prcsub_set_xml_data('g_delivery_info') ;
        prcsub_set_xml_data('new_modify_flg'   , gt_report_data(i).new_modify_flg) ;
        prcsub_set_xml_data('ship_date'
          , TO_CHAR(gt_report_data(i).schedule_ship_date, gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('delivery_no'      , gt_report_data(i).delivery_no) ;
        prcsub_set_xml_data('delivery_kbn'     , gt_report_data(i).shipping_method_code) ;
        prcsub_set_xml_data('delivery_nm'      , gt_report_data(i).shipping_method_name) ;
        prcsub_set_xml_data('carrier_cd'       , gt_report_data(i).career_id) ;
        prcsub_set_xml_data('carrier_nm'       , gt_report_data(i).career_name) ;
        prcsub_set_xml_data('lg_move_info') ;
      END IF ;
--
      -- ���ו�(�ړ�No���)
      IF (lb_dispflg_move_no) THEN
        prcsub_set_xml_data('g_move_info') ;
        prcsub_set_xml_data('zen_delivery_no'  , gt_report_data(i).prev_delivery_no) ;
        prcsub_set_xml_data('move_no'          , gt_report_data(i).mov_num) ;
        prcsub_set_xml_data('ship_cd'          , gt_report_data(i).shipped_locat_code) ;
        prcsub_set_xml_data('ship_nm'          , gt_report_data(i).shipped_locat_name) ;
        prcsub_set_xml_data('tehai_no'         , gt_report_data(i).batch_no) ;
        prcsub_set_xml_data('time_shitei_from' , gt_report_data(i).arrival_time_from) ;
        prcsub_set_xml_data('time_shitei_to'   , gt_report_data(i).arrival_time_to) ;
        prcsub_set_xml_data('tekiyo'           , gt_report_data(i).description) ;
        prcsub_set_xml_data('lg_dtl_info') ;
      END IF;
--
      -- ���ו�(�i�ڃR�[�h���)
      prcsub_set_xml_data('g_dtl_info') ;
      prcsub_set_xml_data('item_cd'            , gt_report_data(i).item_code) ;
      prcsub_set_xml_data('item_nm'            , gt_report_data(i).item_name) ;
      prcsub_set_xml_data('net'                , gt_report_data(i).net) ;
      prcsub_set_xml_data('lot_no'             , gt_report_data(i).lot_no) ;
      prcsub_set_xml_data('lot_date'           , gt_report_data(i).prodct_date) ;
      prcsub_set_xml_data('best_bfr_date'      , gt_report_data(i).best_before_date) ;
      prcsub_set_xml_data('lot_sign'           , gt_report_data(i).uniqe_sign) ;
      prcsub_set_xml_data('num_qty'            , gt_report_data(i).num_qty) ;
      prcsub_set_xml_data('quantity'           , gt_report_data(i).quantity) ;
      prcsub_set_xml_data('tani'               , gt_report_data(i).conv_unit) ;
      prcsub_set_xml_data('/g_dtl_info') ;
--
      -- ====================================================
      -- ���ݏ������̃f�[�^��ێ�
      -- ====================================================
      lv_tmp_nyuko_cd    := gt_report_data(i).ship_to_locat_code ;
      lv_tmp_nyuko_date  := gt_report_data(i).schedule_arrival_date ;
      lv_tmp_delivery_no := gt_report_data(i).delivery_no ;
      lv_tmp_move_no     := gt_report_data(i).mov_num ;
--
      -- ====================================================
      -- �o�͔���
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- �ړ�No
        IF (lv_tmp_move_no = gt_report_data(i+1).mov_num) THEN
          lb_dispflg_move_no     := FALSE ;
        ELSE
          lb_dispflg_move_no     := TRUE ;
        END IF ;
--
        -- �z��No
        IF (lv_tmp_delivery_no = gt_report_data(i+1).delivery_no) THEN
          lb_dispflg_delivery_no := FALSE ;
        ELSE
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_move_no     := TRUE ;
        END IF ;
--
        -- ���ɗ\���
        IF (lv_tmp_nyuko_date = gt_report_data(i+1).schedule_arrival_date) THEN
          lb_dispflg_nyuko_date  := FALSE ;
        ELSE
          lb_dispflg_nyuko_date  := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_move_no     := TRUE ;
        END IF ;
--
        -- ���ɐ�R�[�h
        IF (lv_tmp_nyuko_cd = gt_report_data(i+1).ship_to_locat_code) THEN
          lb_dispflg_nyuko_cd    := FALSE ;
        ELSE
          lb_dispflg_nyuko_cd    := TRUE ;
          lb_dispflg_nyuko_date  := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_move_no     := TRUE ;
        END IF ;
--
      ELSE
          lb_dispflg_nyuko_cd    := TRUE ;
          lb_dispflg_nyuko_date  := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_move_no     := TRUE ;
      END IF;
--
      -- ====================================================
      -- �I���^�O�ݒ�
      -- ====================================================
      IF (lb_dispflg_move_no) THEN
        prcsub_set_xml_data('/lg_dtl_info') ;
        prcsub_set_xml_data('/g_move_info') ;
      END IF;
--
      IF (lb_dispflg_delivery_no) THEN
        prcsub_set_xml_data('/lg_move_info') ;
        prcsub_set_xml_data('/g_delivery_info') ;
      END IF;
--
      IF (lb_dispflg_nyuko_date) THEN
        prcsub_set_xml_data('/lg_delivery_info') ;
        prcsub_set_xml_data('/g_nyuko_yotei_info') ;
      END IF;
--
      IF (lb_dispflg_nyuko_cd) THEN
        prcsub_set_xml_data('/lg_nyuko_yotei_info') ;
        prcsub_set_xml_data('/g_nyuko_info') ;
      END IF;
      
    END LOOP detail_data_loop;
--
    -- ====================================================
    -- �I���^�O�ݒ�
    -- ====================================================
    prcsub_set_xml_data('/lg_nyuko_info') ;
    prcsub_set_xml_data('/data_info') ;
    prcsub_set_xml_data('/root') ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    iv_name  IN VARCHAR2
   ,iv_value IN VARCHAR2
   ,ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_convert_data VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF ;
--
    RETURN(lv_convert_data);
--
  END fnc_convert_into_xml;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT   VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT   VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT   VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain' ;  -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_xml_string    VARCHAR2(32000) ;
    ln_retcode       NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ��������
    -- ===============================================
    prc_initialize(
      ov_errbuf     => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- ���[�f�[�^�擾����
    -- ===============================================
    prc_get_report_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML��������
    -- ==================================================
    prc_create_xml_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML�o�͏���
    -- ==================================================
    -- XML�w�b�_���o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      lv_xml_string := fnc_convert_into_xml(
                         gt_xml_data_table(i).tag_name
                        ,gt_xml_data_table(i).tag_value
                        ,gt_xml_data_table(i).tag_type
                       ) ;
      -- XML�f�[�^�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_xml_string) ;
    END LOOP xml_loop ;
--
    --XML�f�[�^�폜
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn) AND (gt_report_data.COUNT = 0)) THEN
      RAISE no_data_expt ;
    END IF ;
--
  EXCEPTION
    -- *** ���[0����O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf                  OUT    VARCHAR2       -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                 OUT    VARCHAR2       -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_dept                 IN     VARCHAR2       -- 01:����
   ,iv_plan_decide_kbn      IN     VARCHAR2       -- 02:�\��/�m��敪
   ,iv_ship_from            IN     VARCHAR2       -- 03:�o�ɓ�From
   ,iv_ship_to              IN     VARCHAR2       -- 04:�o�ɓ�To
   ,iv_notif_date           IN     VARCHAR2       -- 05:�m��ʒm���{��
   ,iv_notif_time_from      IN     VARCHAR2       -- 06:�m��ʒm���{����From
   ,iv_notif_time_to        IN     VARCHAR2       -- 07:�m��ʒm���{����To
   ,iv_block1               IN     VARCHAR2       -- 08:�u���b�N1
   ,iv_block2               IN     VARCHAR2       -- 09:�u���b�N2
   ,iv_block3               IN     VARCHAR2       -- 10:�u���b�N3
   ,iv_ship_to_locat_code   IN     VARCHAR2       -- 11:���ɐ�
   ,iv_shipped_locat_code   IN     VARCHAR2       -- 12:�o�Ɍ�
   ,iv_freight_carrier_code IN     VARCHAR2       -- 13:�^���Ǝ�
   ,iv_delivery_no          IN     VARCHAR2       -- 14:�z��No
   ,iv_mov_num              IN     VARCHAR2       -- 15:�ړ�No
   ,iv_online_kbn           IN     VARCHAR2       -- 16:�I�����C���Ώۋ敪
   ,iv_item_kbn             IN     VARCHAR2       -- 17:�i�ڋ敪
   ,iv_arrival_date_from    IN     VARCHAR2       -- 18:����From
   ,iv_arrival_date_to      IN     VARCHAR2       -- 19:����To
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- �ϐ������ݒ�
    -- ===============================================
    -- ���̓p�����[�^���O���[�o���ϐ��ɕێ�
    gt_param.dept                 := iv_dept ;                            -- 01:����
    gt_param.plan_decide_kbn      := iv_plan_decide_kbn ;                 -- 02:�\��/�m��敪
    gt_param.ship_from            := FND_DATE.CANONICAL_TO_DATE(iv_ship_from) ; -- 03:�o�ɓ�From
    gt_param.ship_to              := FND_DATE.CANONICAL_TO_DATE(iv_ship_to) ;   -- 04:�o�ɓ�To
    gt_param.notif_date           := FND_DATE.CANONICAL_TO_DATE(iv_notif_date) ;-- 05:�m��ʒm���{��
    gt_param.notif_time_from      := iv_notif_time_from ;                 -- 06:�m��ʒm���{����From
    gt_param.notif_time_to        := iv_notif_time_to ;                   -- 07:�m��ʒm���{����To
    gt_param.block1               := iv_block1 ;                          -- 08:�u���b�N1
    gt_param.block2               := iv_block2 ;                          -- 09:�u���b�N2
    gt_param.block3               := iv_block3 ;                          -- 10:�u���b�N3
    gt_param.ship_to_locat_code   := iv_ship_to_locat_code ;              -- 11:���ɐ�
    gt_param.shipped_locat_code   := iv_shipped_locat_code ;              -- 12:�o�Ɍ�
    gt_param.freight_carrier_code := iv_freight_carrier_code ;            -- 13:�^���Ǝ�
    gt_param.delivery_no          := iv_delivery_no ;                     -- 14:�z��No
    gt_param.mov_num              := iv_mov_num ;                         -- 15:�ړ�No
    gt_param.online_kbn           := iv_online_kbn ;                      -- 16:�I�����C���Ώۋ敪
    gt_param.item_kbn             := iv_item_kbn ;                        -- 17:�i�ڋ敪
    gt_param.arrival_date_from    := FND_DATE.CANONICAL_TO_DATE(iv_arrival_date_from);-- 18:����From
    gt_param.arrival_date_to      := FND_DATE.CANONICAL_TO_DATE(iv_arrival_date_to) ; -- 19:����To
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh620003c;
/

