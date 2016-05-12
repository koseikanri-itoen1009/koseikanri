CREATE OR REPLACE PACKAGE BODY XXWSH920007C_OT
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920007C_OT(body)
 * Description      : ���Y����(�����A�z��)
 * MD.050           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD050_BPO_920
 * MD.070           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD070_BPO92A
 * Version          : 1.16
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  check_sql_pattern      �����p�^�[���`�F�b�N
 *  fwd_sql_create         A-2 SQL���쐬
 *  get_demand_inf_fwd     A-3 �ړ��pSQL���쐬
 *  check_parameter        A-1  ���̓p�����[�^�`�F�b�N
 *  release_lock           ���b�N��������
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20   1.0   SCS �k����        �V�K�쐬
 *  2008/12/01   1.2   SCS �{�c          ���b�N�Ή�
 *  2008/12/20   1.3   SCS �k����        �{�ԏ�Q#738
 *  2009/01/19   1.4   SCS �쑺          �{�ԏ�Q#1038
 *  2009/01/27   1.5   SCS ��r          �{�ԏ�Q#332�Ή��i�����F�o�Ɍ��s���Ή��j
 *  2009/01/28   1.6   SCS �ɓ�          �{�ԏ�Q#1028�Ή��i�p�����[�^�Ɏw�������ǉ��j
 *  2009/01/28   1.7   SCS ��r          �{�ԏ�Q#949�Ή��i�g���[�X�擾�p�����ǉ��j
 *  2009/02/03   1.8   SCS ��r          �{�ԏ�Q#949�Ή��i�g���[�X�擾�p�����폜�j
 *  2009/02/18   1.9   SCS �쑺          �{�ԏ�Q#1176�Ή�
 *  2009/02/19   1.10  SCS �쑺          �{�ԏ�Q#1176�Ή��i�ǉ��C���j
 *  2009/04/03   1.11  SCS �쑺          �{�ԏ�Q#1367�i1321�j�����p�Ή�
 *  2009/04/17   1.12  SCS �쑺          �{�ԏ�Q#1367�i1321�j���g���C�Ή�
 *  2009/05/01   1.13  SCS �쑺          �{�ԏ�Q#1367�i1321�j�q���O�Ή�
 *  2009/05/19   1.14  SCS �ɓ�          �{�ԏ�Q#1447�Ή�
 *  2010/01/18   1.15  SCS �k����        �{�ԉғ���Q#701�Ή� �i��0005000�̓v���g�ł�
 *                                       ���s����悤�ɏC��
 *  2009/01/21   1.16  SCS �k����        �{�ԉғ���Q#701�Ή� �v���g�ł̃e�X�g���I���������
 *                                       �i��0005000�̓v���g�ł����s���Ȃ��悤�ɏC��
 *  2016/05/11   1.16' SCSK�������      E_�{�ғ�_13468�Ή� �^�p�e�X�g���W���[���Ƃ��č쐬�A
 *                                       XXWSH920008C_OT���Ăяo���Bv.1.16�Ɩ{�Ԋ��ŕ���������B
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
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
  lock_expt              EXCEPTION;     -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXPT920001C';       -- �p�b�P�[�W��
  --���b�Z�[�W�ԍ�
  gv_msg_92a_002       CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10033';    -- �p�����[�^������
  gv_msg_92a_003       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12857';    -- �p�����[�^����
  gv_msg_92a_004       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12953';    -- FromTo�t�]
  gv_msg_92a_009       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11222';    -- �p�����[�^����
  gv_msg_xxcmn10135    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';   -- �v���̔��s���s�G���[
  --�萔
  gv_mst_normal        CONSTANT VARCHAR2(10)  := '����I��';
  gv_mst_warn          CONSTANT VARCHAR2(10)  := '�x���I��';
  gv_mst_error         CONSTANT VARCHAR2(10)  := '�ُ�I��';
  gv_cons_item_class   CONSTANT VARCHAR2(100) := '���i�敪';
  gv_cons_msg_kbn_wsh  CONSTANT VARCHAR2(5)   := 'XXWSH';              -- ���b�Z�[�W�敪XXWSH
  gv_cons_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';              -- ���b�Z�[�W�敪XXCMN
  gv_cons_deliv_from   CONSTANT VARCHAR2(100) := '�o�ɓ�From';
  gv_cons_deliv_to     CONSTANT VARCHAR2(100) := '�o�ɓ�To';
  gv_cons_t_deliv      CONSTANT VARCHAR2(1)   := '1';                  -- '�o�׈˗�'
  gv_cons_biz_t_move   CONSTANT VARCHAR2(2)   := '20';                 -- '�ړ��w��'(�����^�C�v)
  gv_cons_biz_t_deliv  CONSTANT VARCHAR2(2)   := '10';                 -- '�o�׈˗�'
  gv_cons_input_param  CONSTANT VARCHAR2(100) := '���̓p�����[�^�l';   -- '���̓p�����[�^�l'
  gv_cons_flg_yes      CONSTANT VARCHAR2(1)   := 'Y';                  -- �t���O 'Y'
  gv_cons_flg_no       CONSTANT VARCHAR2(1)   := 'N';                  -- �t���O 'N'
  gv_cons_notif_status CONSTANT VARCHAR2(3)   := '40';                 -- �u�m��ʒm�ρv
  gv_cons_status       CONSTANT VARCHAR2(2)   := '03';                 -- �u���ߍς݁v
  gv_cons_lot_ctl      CONSTANT VARCHAR2(1)   := '1';                  -- �u���b�g�Ǘ��i�v
  gv_cons_item_product CONSTANT VARCHAR2(1)   := '5';                  -- �u���i�v
  gv_cons_move_type    CONSTANT VARCHAR2(1)   := '1';                  -- �u�ϑ�����v
  gv_cons_mov_sts_c    CONSTANT VARCHAR2(2)   := '03';                 -- �u�������v
  gv_cons_mov_sts_e    CONSTANT VARCHAR2(2)   := '02';                 -- �u�˗��ρv
  gv_cons_order_lines  CONSTANT VARCHAR2(50)  := '�󒍖��׃A�h�I��';
  gv_cons_instr_lines  CONSTANT VARCHAR2(50)  := '�ړ��˗�/�w������(�A�h�I��)';
  gv_cons_error        CONSTANT VARCHAR2(1)   := '1';                  -- ���ʊ֐��ł̃G���[
  gv_cons_no_judge     CONSTANT VARCHAR2(2)   := '10';                 -- �u������v
  gv_cons_am_auto      CONSTANT VARCHAR2(2)   := '10';                 -- �u���������v
  gv_cons_rec_type     CONSTANT VARCHAR2(2)   := '10';                 -- �u�w���v
  gv_cons_id_drink     CONSTANT VARCHAR2(1)   := '2';                  -- ���i�敪�E�h�����N
  gv_cons_id_leaf      CONSTANT VARCHAR2(1)   := '1';                  -- ���i�敪�E���[�t
  gv_cons_deliv_fm     CONSTANT VARCHAR2(50)  := '�o�׌�';             -- �o�׌�
  gv_cons_deliv_tp     CONSTANT VARCHAR2(50)  := '�o�׌`��';           -- �o�׌`��^
  gv_cons_number       CONSTANT VARCHAR2(50)  := '���l';               -- ���l^
  --�g�[�N��
  gv_tkn_parm_name     CONSTANT VARCHAR2(15)  := 'PARM_NAME';          -- �p�����[�^
  gv_tkn_param_name    CONSTANT VARCHAR2(15)  := 'PARAM_NAME';         -- �p�����[�^
  gv_tkn_parameter     CONSTANT VARCHAR2(15)  := 'PARAMETER';          -- �p�����[�^��
  gv_tkn_type          CONSTANT VARCHAR2(15)  := 'TYPE';               -- �����^�C�v
  gv_tkn_table         CONSTANT VARCHAR2(15)  := 'TABLE';              -- �e�[�u��
  gv_tkn_err_code      CONSTANT VARCHAR2(15)  := 'ERR_CODE';           -- �G���[�R�[�h
  gv_tkn_err_msg       CONSTANT VARCHAR2(15)  := 'ERR_MSG';            -- �G���[���b�Z�[�W
  gv_tkn_ship_type     CONSTANT VARCHAR2(15)  := 'SHIP_TYPE';          -- �z����
  gv_tkn_item          CONSTANT VARCHAR2(15)  := 'ITEM';               -- �i��
  gv_tkn_lot           CONSTANT VARCHAR2(15)  := 'LOT';                -- ���b�gNo
  gv_tkn_request_type  CONSTANT VARCHAR2(15)  := 'REQUEST_TYPE';       -- �˗�No/�ړ��ԍ�_�敪
  gv_tkn_p_date        CONSTANT VARCHAR2(15)  := 'P_DATE';             -- ������
  gv_tkn_use_by_date   CONSTANT VARCHAR2(15)  := 'USE_BY_DATE';        -- �ܖ�����
  gv_tkn_fix_no        CONSTANT VARCHAR2(15)  := 'FIX_NO';             -- �ŗL�L��
  gv_tkn_request_no    CONSTANT VARCHAR2(15)  := 'REQUEST_NO';         -- �˗�No
  gv_tkn_item_no       CONSTANT VARCHAR2(15)  := 'ITEM_NO';            -- �i�ڃR�[�h
  gv_tkn_reverse_date  CONSTANT VARCHAR2(15)  := 'REVDATE';            -- �t�]���t
  gv_tkn_arrival_date  CONSTANT VARCHAR2(15)  := 'ARRIVAL_DATE';       -- ���ד��t
  gv_tkn_ship_to       CONSTANT VARCHAR2(15)  := 'SHIP_TO';            -- �z����
  gv_tkn_standard_date CONSTANT VARCHAR2(15)  := 'STANDARD_DATE';      -- ����t
  gv_request_name_ship CONSTANT VARCHAR2(15)  := '�˗�No';             -- �˗�No
  gv_request_name_move CONSTANT VARCHAR2(15)  := '�ړ��ԍ�';           -- �ړ��ԍ�
  gv_ship_name_ship    CONSTANT VARCHAR2(15)  := '�z����';             -- �z����
  gv_ship_name_move    CONSTANT VARCHAR2(15)  := '���ɐ�';             -- ���ɐ�
-- Ver1.3 M.Hokkanji Start
  gv_req_nodata        CONSTANT VARCHAR2(15)  := '3';                  -- �Ώۃf�[�^����
-- Ver1.3 M.Hokkanji End
  --�v���t�@�C��
  gv_action_type_ship  CONSTANT VARCHAR2(2)   := '1';                  -- �o��
  gv_action_type_move  CONSTANT VARCHAR2(2)   := '3';                  -- �ړ�
  gv_base              CONSTANT VARCHAR2(1)   := '1'; -- ���_
  gv_wzero             CONSTANT VARCHAR2(2)   := '00';
  gv_flg_no            CONSTANT VARCHAR2(1)   := 'N';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_total_cnt         NUMBER :=0;       -- �Ώی���
  gd_yyyymmdd_from     DATE;             -- ���̓p�����[�^�o�ɓ�From
  gd_yyyymmdd_to       DATE;             -- ���̓p�����[�^�o�ɓ�To
  gv_yyyymmdd_from     VARCHAR2(10);     -- ���̓p�����[�^�o�ɓ�From
  gv_yyyymmdd_to       VARCHAR2(10);     -- ���̓p�����[�^�o�ɓ�To
  gn_login_user        NUMBER;           -- ���O�C��ID
  gn_created_by        NUMBER;           -- ���O�C�����[�UID
  gn_conc_request_id   NUMBER;           -- �v��ID
  gn_prog_appl_id      NUMBER;           -- �A�v���P�[�V����ID
  gn_conc_program_id   NUMBER;           -- �v���O����ID
  gt_item_class        xxcmn_lot_status_v.prod_class_code%TYPE;  -- ���i�敪
--
  -- ���v���̃f�[�^���i�[���郌�R�[�h
  TYPE demand_rec IS RECORD(
     item_code         xxwsh_order_lines_all.shipping_item_code%TYPE -- �i��(�R�[�h) V
   , total_cnt         NUMBER                                        -- ����
  );
  TYPE demand_tbl IS TABLE OF demand_rec INDEX BY PLS_INTEGER;
  gr_demand_tbl  demand_tbl;
-- Ver1.3 M.Hokkanji Start
  TYPE data_cnt_rec IS RECORD(
      error_cnt        NUMBER            -- ���̓��̃G���[����
    , warn_cnt         NUMBER            -- ���̓��̌x������
    , nomal_cnt        NUMBER            -- ���̓��̐��팏��
    , ship_date        VARCHAR2(10)      -- �����Ώۓ��t
  );
  TYPE data_cnt_tbl IS TABLE OF data_cnt_rec INDEX BY PLS_INTEGER;
  gr_data_cnt_tbl data_cnt_tbl;
-- Ver1.3 M.Hokkanji End
--
  /**********************************************************************************
  * Function Name    : check_sql_pattern
  * Description      : SQL�����p�^�[���`�F�b�N�֐�
  ***********************************************************************************/
  FUNCTION check_sql_pattern(iv_kubun           IN  VARCHAR2,              -- �o�ׁE�ړ��敪
                             iv_block1          IN  VARCHAR2 DEFAULT NULL, -- �u���b�N�P
                             iv_block2          IN  VARCHAR2 DEFAULT NULL, -- �u���b�N�Q
                             iv_block3          IN  VARCHAR2 DEFAULT NULL, -- �u���b�N�R
                             in_deliver_from_id IN  NUMBER   DEFAULT NULL, -- �o�Ɍ�
                             in_deliver_type    IN  NUMBER   DEFAULT NULL) -- �o�Ɍ`��
                             RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_sql_pattern'; --�v���O������
--
    -- *** ���[�J���ϐ� ***
    ln_pattern1         NUMBER := 0;
    ln_return_pattern   NUMBER := 0;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
  BEGIN
    --==============================================================
    -- �C�ӓ��͂𔻒f(�o�ׂ̏ꍇ�j
    --   1 = �u���b�N1�`3 ���S��NULL
    --   2 = �o�׌� ��NULL
    --   3 = �󒍃^�C�v ��NULL
    -- �����̑g�ݍ��킹�ł̏�������у��^�[���l�͉��L�̂悤�ɂȂ�
    --   1<>, 2<>, 3<> �� (1 or 2) and 3 �� 1
    --   1= , 2= , 3<> �� 3              �� 2
    --   1= , 2<>, 3<> �� 2 and 3        �� 3
    --   1<>, 2= , 3<> �� 1 and 3        �� 4
    --   1<>, 2<>, 3=  �� 1 or 2         �� 5
    --   1= , 2= , 3=  �� �Ȃ�           �� 6
    --   1= , 2<>, 3=  �� 2              �� 7
    --   1<>, 2= , 3=  �� 1              �� 8
    -- �C�ӓ��͂𔻒f(�ړ��̏ꍇ�j===================================
    --   1 = �u���b�N1�`3 ���S��NULL
    --   2 = �o�׌� ��NULL
    -- �����̑g�ݍ��킹�ł̏�������у��^�[���l�͉��L�̂悤�ɂȂ�
    --   1<>, 2<>      �� (1 or 2)       �� 5
    --   1= , 2=       �� �Ȃ�           �� 6
    --   1= , 2<>      �� 2              �� 7
    --   1<>, 2=       �� 1              �� 8
    --==============================================================
--
    -- �u���b�N�P�`�R�S�Ă�NULL���H
    IF (    ( iv_block1 IS NULL ) 
        AND ( iv_block2 IS NULL ) 
        AND ( iv_block3 IS NULL ) ) THEN
      ln_pattern1 := 1;
    END IF;
--
    -- �u�o�ׁv�̏ꍇ
    IF( iv_kubun = gv_cons_biz_t_deliv) THEN
      -- �p�^�[���P
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) 
          AND ( in_deliver_type    IS NOT NULL )) THEN
        RETURN 1;
      END IF;
--
      -- �p�^�[���Q
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NULL ) 
          AND ( in_deliver_type    IS NOT NULL ) ) THEN
        RETURN 2;
      END IF;
--
      -- �p�^�[���R
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) 
          AND ( in_deliver_type    IS NOT NULL ) ) THEN
        RETURN 3;
      END IF;
--
      -- �p�^�[���S
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NULL ) 
          AND ( in_deliver_type    IS NOT NULL ) ) THEN
        RETURN 4;
      END IF;
--
      -- �p�^�[���T
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) 
          AND ( in_deliver_type    IS NULL     ) ) THEN
        RETURN 5;
      END IF;
--
      -- �p�^�[���U
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NULL ) 
          AND ( in_deliver_type    IS NULL ) ) THEN
        RETURN 6;
      END IF;
--
      -- �p�^�[���V
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) 
          AND ( in_deliver_type IS NULL        ) ) THEN
        RETURN 7;
      END IF;
--
      -- �p�^�[���W
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NULL ) 
          AND ( in_deliver_type    IS NULL ) ) THEN
        RETURN 8;
      END IF;
--
    -- �u�ړ��v�̏ꍇ
    ELSE
      -- �p�^�[���T
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) ) THEN
        RETURN 5;
      END IF;
--
      -- �p�^�[���U
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NULL ) ) THEN
        RETURN 6;
      END IF;
--
      -- �p�^�[���V
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) ) THEN
        RETURN 7;
      END IF;
--
      -- �p�^�[���W
      IF (    (ln_pattern1 <> 1 ) 
          AND (in_deliver_from_id IS NULL ) ) THEN
        RETURN 8;
      END IF;
    END IF;
    RAISE process_exp;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_sql_pattern;
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : A-1  ���̓p�����[�^�`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_item_class         IN   VARCHAR2,     -- ���i�敪
    iv_deliver_date_from  IN   VARCHAR2,     -- �o�ɓ�From
    iv_deliver_date_to    IN   VARCHAR2,     -- �o�ɓ�To
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ************************************
    -- ***  ���̓p�����[�^�K�{�`�F�b�N  ***
    -- ************************************
    -- ���i�敪�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_item_class IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                    ,gv_msg_92a_002    -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_param_name    -- �g�[�N��'PARAM_NAME'
                                                    ,gv_cons_item_class) -- '���i�敪'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�ɓ�From�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_deliver_date_from IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                    ,gv_msg_92a_002    -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_param_name    -- �g�[�N��'PARAM_NAME'
                                                    ,gv_cons_deliv_from) -- '�o�ɓ�From'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�ɓ�To�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_deliver_date_to IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                    ,gv_msg_92a_002    -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                                                    ,gv_cons_deliv_to) -- '�o�ɓ�To'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- ******************************
    -- ***  �Ώۊ��ԏ����`�F�b�N  ***
    -- ******************************
    -- �o�ɓ�From��YYYY/MM/DD�̌^�ɕϊ�(NULL���A���Ă�����G���[�j
    gv_yyyymmdd_from := iv_deliver_date_from;
    gd_yyyymmdd_from := FND_DATE.STRING_TO_DATE(iv_deliver_date_from, 'YYYY/MM/DD');
    IF (gd_yyyymmdd_from IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_92a_003    -- ���̓p�����[�^�����G���[
                                                    ,gv_tkn_parm_name  -- �g�[�N��'PARM_NAME'
                                                    ,gv_cons_deliv_from) -- '�o�ɓ�From'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�ɓ�From��YYYY/MM/DD�̌^�ɕϊ�(NULL���A���Ă�����G���[�j
    gv_yyyymmdd_to := iv_deliver_date_to;
    gd_yyyymmdd_to := FND_DATE.STRING_TO_DATE(iv_deliver_date_to, 'YYYY/MM/DD');
    IF (gd_yyyymmdd_to IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_92a_003    -- ���̓p�����[�^�����G���[
                                                    ,gv_tkn_parm_name  -- �g�[�N��'PARM_NAME'
                                                    ,gv_cons_deliv_to)   -- '�o�ɓ�To'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- ******************************
    -- ***  �Ώۊ��ԋt�]�`�F�b�N  ***
    -- ******************************
    -- �o�ɓ�From�Əo�ɓ�To���t�]���Ă�����G���[
    IF (gd_yyyymmdd_from > gd_yyyymmdd_to) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_92a_004)    -- ���̓p�����[�^�����G���[
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
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
  END check_parameter;
--
  /**********************************************************************************
  * Function Name    : fwd_sql_create
  * Description      : A-2  SQL���쐬�֐�
  ***********************************************************************************/
  FUNCTION fwd_sql_create(
    iv_action_type     IN  VARCHAR2               -- �������
  , iv_block1          IN  VARCHAR2 DEFAULT NULL  -- �u���b�N�P
  , iv_block2          IN  VARCHAR2 DEFAULT NULL  -- �u���b�N�Q
  , iv_block3          IN  VARCHAR2 DEFAULT NULL  -- �u���b�N�R
  , in_deliver_from_id IN  NUMBER   DEFAULT NULL  -- �o�Ɍ�
  , in_deliver_type    IN  NUMBER   DEFAULT NULL  -- �o�Ɍ`��
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
  , iv_instruction_dept IN  VARCHAR2              -- �w������
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start �{�ԏ�Q#1447�Ή�
  , iv_item_code        IN  VARCHAR2              -- �i�ڃR�[�h
-- 2009/05/19 H.Itou Add End
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fwd_sql_create'; --�v���O������
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
-- 
    -- *** ���[�J���ϐ� ***
    ln_pattern     NUMBER := 0;
    lv_fwd_sql     VARCHAR2(32767);   -- SQL���i�[�o�b�t�@
--
  BEGIN
    -- SQL�����p�^�[���`�F�b�N
    ln_pattern := check_sql_pattern(gv_cons_biz_t_deliv,
                                    iv_block1,
                                    iv_block2,
                                    iv_block3,
                                    in_deliver_from_id,
                                    in_deliver_type);
    -- ***********
    -- SQL���g�ݗ���(�Œ蕔��)
    -- ***********
    lv_fwd_sql  := ' SELECT data.item_no item_code ' -- �i�ڃR�[�h
                || '      , SUM(data.cnt)  total_cnt ' -- ����
                || ' FROM   ( ';
    -- ������ʂ�Null�܂��́A�o�ׂ̏ꍇ
    IF ( ( iv_action_type IS NULL ) OR ( iv_action_type = gv_action_type_ship ) ) THEN
      -- ***********
      -- SQL���g�ݗ���(�o�׌Œ蕔��)
      -- ***********
      lv_fwd_sql  := lv_fwd_sql 
                    || ' SELECT  im2.item_no item_no '              -- �i��(�R�[�h)
                          || ' , COUNT(1)              cnt '          -- ����
                    || ' FROM    xxcmn_item_locations2_v        il '  -- OPM�ۊǏꏊ�}�X�^
                          || ' , xxwsh_order_headers_all        oh '  -- �󒍃w�b�_�A�h�I��
                          || ' , xxcmn_cust_accounts2_v         p  '  -- �ڋq���VIEW
                          || ' , xxwsh_oe_transaction_types2_v  tt '  -- �󒍃^�C�v
                          || ' , xxwsh_order_lines_all          ol '  -- �󒍖��׃A�h�I��
                          || ' , xxcmn_item_mst2_v              im '  -- OPM�i�ڃ}�X�^
                          || ' , xxcmn_item_mst2_v              im2 ' -- OPM�i�ڃ}�X�^
                          || ' , xxcmn_item_categories5_v       ic '  -- �J�e�S�����VIEW
                    || ' WHERE   il.inventory_location_id = oh.deliver_from_id '
                    || ' AND     oh.schedule_ship_date   >= TO_DATE( :para_yyyymmdd_from, ''YYYY/MM/DD'') ' 
                    || ' AND     oh.schedule_ship_date   <= TO_DATE( :para_yyyymmdd_to  , ''YYYY/MM/DD'') '
                    || ' AND     p.party_number           = oh.head_sales_branch ' 
                    || ' AND     p.start_date_active     <= oh.schedule_ship_date '
                    || ' AND     p.end_date_active       >= oh.schedule_ship_date '  
                    || ' AND     p.customer_class_code    = :para_base '
                    || ' AND     oh.order_type_id         = tt.transaction_type_id '
                    || ' AND     tt.shipping_shikyu_class = :para_cons_t_deliv '
                    || ' AND     oh.req_status            = :para_cons_status '
                    || ' AND     NVL(oh.notif_status, :para_wzero ) <> :para_cons_notif_status '
                    || ' AND     oh.latest_external_flag  = :para_cons_flg_yes '
                    || ' AND     ol.order_header_id       = oh.order_header_id ' 
                    || ' AND     NVL(ol.delete_flag, :para_flg_no ) <> :para_cons_flg_yes '
                    || ' AND     il.date_from            <= oh.schedule_ship_date '
                    || ' AND    ((il.date_to             >= oh.schedule_ship_date) OR (il.date_to IS NULL)) '
                    || ' AND     tt.start_date_active    <= oh.schedule_ship_date '
                    || ' AND    ((tt.end_date_active     >= oh.schedule_ship_date) OR (tt.end_date_active IS NULL)) '
                    || ' AND     im.start_date_active    <= oh.schedule_ship_date '
                    || ' AND    ((im.end_date_active     >= oh.schedule_ship_date) OR (im.end_date_active IS NULL)) '
                    || ' AND     ol.automanual_reserve_class IS NULL '
                    || ' AND     im.item_id              = ic.item_id '
                    || ' AND     im.item_no              = ol.shipping_item_code '
                    || ' AND     im.lot_ctl              = :para_cons_lot_ctl ' 
                    || ' AND     ic.item_class_code      = :para_cons_item_product ' 
                    || ' AND     ic.prod_class_code      = :para_item_class '
                    || ' AND     im.parent_item_id       = im2.item_id '
                    || ' AND     im2.start_date_active   <= oh.schedule_ship_date '
                    || ' AND    ((im2.end_date_active    >= oh.schedule_ship_date) OR (im2.end_date_active IS NULL)) ';
  --
      -- ***********
      -- SQL���g�ݗ���(�o�וϓ�����)
      -- ***********
      CASE ln_pattern
        WHEN 1 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND (   ( il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                                  '''' || iv_block2 || '''' || ',' ||
                                                                                  '''' || iv_block3 || '''' || '))'
                                   || '      OR ( oh.deliver_from = ' || in_deliver_from_id || ' ) ) '
                                   || ' AND oh.order_type_id  =  '    || in_deliver_type;
        WHEN 2 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND oh.order_type_id  = '     || in_deliver_type ;
        WHEN 3 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND oh.deliver_from   = '     || in_deliver_from_id
                                   || ' AND oh.order_type_id  = '     || in_deliver_type ;
        WHEN 4 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                            '''' || iv_block2 || '''' || ',' ||
                                                                            '''' || iv_block3 || '''' || ') '
                                   || ' AND oh.order_type_id = '      || in_deliver_type ;
        WHEN 5 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND (   (il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                                 '''' || iv_block2 || '''' || ',' ||
                                                                                 '''' || iv_block3 || '''' || '))'
-- 2009/01/27 D.Nihei Mod Start �{��#332�Ή�
--                                   || '      OR (oh.deliver_from = '  || in_deliver_from_id || ')) ';
                                   || '      OR (oh.deliver_from = '''  || in_deliver_from_id || ''')) ';
-- 2009/01/27 D.Nihei Mod End
        --WHEN 6 �͏����ǉ��Ȃ�
        WHEN 7 THEN
-- 2009/01/27 D.Nihei Mod Start �{��#332�Ή�
--          lv_fwd_sql := lv_fwd_sql || ' AND oh.deliver_from   = '     || in_deliver_from_id ;
          lv_fwd_sql := lv_fwd_sql || ' AND oh.deliver_from   = '''     || in_deliver_from_id || '''';
-- 2009/01/27 D.Nihei Mod End
        WHEN 8 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                            '''' || iv_block2 || '''' || ',' ||
                                                                            '''' || iv_block3 || '''' || ') ';
        ELSE NULL;
      END CASE;
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
      IF (iv_instruction_dept IS NOT NULL) THEN
        lv_fwd_sql := lv_fwd_sql || ' AND oh.instruction_dept = '''|| iv_instruction_dept ||'''';
      END IF;
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start �{�ԏ�Q#1447�Ή�
      IF (iv_item_code IS NOT NULL) THEN
        lv_fwd_sql := lv_fwd_sql || ' AND im2.item_no = '''|| iv_item_code ||'''';
      END IF;
-- 2009/05/19 H.Itou Add End
      -- ***********
      -- GROUP BY��(�o��)
      -- ***********
      lv_fwd_sql := lv_fwd_sql || ' GROUP BY im2.item_no ';
    END IF;
    -- ������ʂ�Null�̏ꍇ��UNION����Z�b�g
    IF ( iv_action_type IS NULL ) THEN
     lv_fwd_sql := lv_fwd_sql || ' UNION ALL ';
    END IF;
    -- ������ʂ�Null�܂��́A�ړ��̏ꍇ
    IF ( ( iv_action_type IS NULL ) OR ( iv_action_type = gv_action_type_move ) ) THEN
      -- SQL�����p�^�[���`�F�b�N
      ln_pattern := check_sql_pattern(gv_cons_biz_t_move,
                                      iv_block1,
                                      iv_block2,
                                      iv_block3,
                                      in_deliver_from_id,
                                      in_deliver_type);
      -- ***********
      -- SQL���g�ݗ���(�ړ��Œ蕔��)
      -- ***********
      lv_fwd_sql  := lv_fwd_sql 
                    || ' SELECT im2.item_no item_no '             -- �i��(�R�[�h)
                          || ' , COUNT(1)              cnt '          -- ����
                    || ' FROM   xxcmn_item_locations2_v       il '  -- OPM�ۊǏꏊ�}�X�^
                         || ' , xxinv_mov_req_instr_headers   ih '  -- �ړ��˗�/�w���w�b�_�A�h�I��
                         || ' , xxinv_mov_req_instr_lines     ml '  -- �ړ��˗�/�w�����׃A�h�I��
                         || ' , xxcmn_item_mst2_v             im '  -- OPM�i�ڃ}�X�^
                         || ' , xxcmn_item_mst2_v             im2'  -- OPM�i�ڃ}�X�^(�e�i�ڎ擾�p)
                         || ' , xxcmn_item_categories5_v      ic '  -- �J�e�S�����VIEW
                    || ' WHERE  il.inventory_location_id = ih.shipped_locat_id '
                    || ' AND    ih.mov_type              = :para_cons_move_type '
                    || ' AND    ih.schedule_ship_date   >= TO_DATE( :para_yyyymmdd_from, ''YYYY/MM/DD'') '
                    || ' AND    ih.schedule_ship_date   <= TO_DATE( :para_yyyymmdd_to  , ''YYYY/MM/DD'') '
                    || ' AND   ((ih.status = :para_cons_mov_sts_c ) OR (ih.status = :para_cons_mov_sts_e )) '
                    || ' AND    NVL(ih.notif_status, :para_wzero ) <> :para_cons_notif_status '
                    || ' AND    ml.mov_hdr_id = ih.mov_hdr_id '
                    || ' AND    NVL(ml.delete_flg, :para_flg_no ) <> :para_cons_flg_yes '
                    || ' AND    il.date_from             <= ih.schedule_ship_date '
                    || ' AND   ((il.date_to              >= ih.schedule_ship_date) OR (il.date_to IS NULL)) '
                    || ' AND    im.start_date_active     <= ih.schedule_ship_date '
                    || ' AND   ((im.end_date_active      >= ih.schedule_ship_date) OR (im.end_date_active IS NULL)) '
                    || ' AND    ml.automanual_reserve_class IS NULL '
                    || ' AND    im.item_no         = ml.item_code '
                    || ' AND    im.item_id         = ic.item_id '
                    || ' AND    im.lot_ctl         = :para_cons_lot_ctl '
                    || ' AND    ic.item_class_code = :para_cons_item_product '
                    || ' AND    ic.prod_class_code = :para_item_class '
                    || ' AND    im.parent_item_id  = im2.item_id '
                    || ' AND    im2.start_date_active     <= ih.schedule_ship_date '
                    || ' AND   ((im2.end_date_active      >= ih.schedule_ship_date) OR (im2.end_date_active IS NULL)) ';
      -- ***********
      -- SQL���g�ݗ���(�ړ��ϓ�����)
      -- ***********
      CASE ln_pattern
        WHEN 5 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND (   (il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                                 '''' || iv_block2 || '''' || ',' ||
                                                                                 '''' || iv_block3 || '''' || '))'
-- 2009/01/27 D.Nihei Mod Start �{��#332�Ή�
--                                   || '      OR (ih.shipped_locat_id = ' || in_deliver_from_id || ')) ';
                                   || '      OR (ih.shipped_locat_code = ''' || in_deliver_from_id || ''')) ';
-- 2009/01/27 D.Nihei Mod End
        --WHEN 6 �͏����ǉ��Ȃ�
        WHEN 7 THEN
-- 2009/01/27 D.Nihei Mod Start �{��#332�Ή�
--          lv_fwd_sql := lv_fwd_sql || ' AND ih.shipped_locat_code   = ' || in_deliver_from_id ;
          lv_fwd_sql := lv_fwd_sql || ' AND ih.shipped_locat_code   = ''' || in_deliver_from_id || '''';
-- 2009/01/27 D.Nihei Mod End
        WHEN 8 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                            '''' || iv_block2 || '''' || ',' ||
                                                                            '''' || iv_block3 || '''' || ') ';
        ELSE NULL;
      END CASE;
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
      IF (iv_instruction_dept IS NOT NULL) THEN
        lv_fwd_sql := lv_fwd_sql || ' AND ih.instruction_post_code = '''|| iv_instruction_dept ||'''';
      END IF;
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start �{�ԏ�Q#1447�Ή�
      IF (iv_item_code IS NOT NULL) THEN
        lv_fwd_sql := lv_fwd_sql || ' AND im2.item_no = '''|| iv_item_code ||'''';
      END IF;
-- 2009/05/19 H.Itou Add End
      -- ***********
      -- GROUP BY��(�ړ�)
      -- ***********
      lv_fwd_sql := lv_fwd_sql || ' GROUP BY im2.item_no ';
    END IF;
    -- ***********
    -- SQL���g�ݗ���(���ʌŒ蕔��)
    -- ***********
    lv_fwd_sql  := lv_fwd_sql || ') data ';
    -- ***********
    -- GROUP BY��(����)
    -- ***********
    lv_fwd_sql := lv_fwd_sql || ' GROUP BY data.item_no ';
    -- ***********
    -- ORDER BY��(����)
    -- ***********
    lv_fwd_sql := lv_fwd_sql || ' ORDER BY total_cnt desc';
--
    -- �쐬����SQL����Ԃ�
    RETURN lv_fwd_sql;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END fwd_sql_create;
--
  /**********************************************************************************
   * Procedure Name   : get_demand_inf_fwd
   * Description      : A-3  �i�ڃR�[�h�擾
   ***********************************************************************************/
  PROCEDURE get_demand_inf_fwd(
    iv_action_type IN  VARCHAR2            -- �������
-- Ver1.3 M.Hokkanji Start
   ,iv_loop_date   IN  VARCHAR2            -- �Ώۗ\���
-- Ver1.3 M.Hokkanji End
  , iv_fwd_sql     IN  VARCHAR2            -- SQL��
  , ov_errbuf      OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_demand_inf_fwd'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE cursor_type IS REF CURSOR;
    fwd_cur cursor_type;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    IF ( iv_action_type = gv_action_type_ship) THEN
-- Ver1.3 M.Hokkanji Start
--      OPEN fwd_cur FOR iv_fwd_sql USING gv_yyyymmdd_from
--                                      , gv_yyyymmdd_to
      OPEN fwd_cur FOR iv_fwd_sql USING iv_loop_date
                                      , iv_loop_date
-- Ver1.3 M.Hokkanji End
                                      , gv_base
                                      , gv_cons_t_deliv
                                      , gv_cons_status
                                      , gv_wzero
                                      , gv_cons_notif_status
                                      , gv_cons_flg_yes
                                      , gv_flg_no
                                      , gv_cons_flg_yes
                                      , gv_cons_lot_ctl
                                      , gv_cons_item_product
                                      , gt_item_class;
    ELSIF ( iv_action_type = gv_action_type_move) THEN
      OPEN fwd_cur FOR iv_fwd_sql USING
      -- Add Start
                                      gv_cons_move_type
      -- Add End
-- Ver1.3 M.Hokkanji Start
--                                      , gv_yyyymmdd_from
--                                      , gv_yyyymmdd_to
                                      , iv_loop_date
                                      , iv_loop_date
-- Ver1.3 M.Hokkanji End
                                      , gv_cons_mov_sts_c
                                      , gv_cons_mov_sts_e
                                      , gv_wzero
                                      , gv_cons_notif_status
                                      , gv_flg_no
                                      , gv_cons_flg_yes
                                      , gv_cons_lot_ctl
                                      , gv_cons_item_product
                                      , gt_item_class;
    ELSIF (iv_action_type IS NULL) THEN
-- Ver1.3 M.Hokkanji Start
--      OPEN fwd_cur FOR iv_fwd_sql USING gv_yyyymmdd_from
--                                      , gv_yyyymmdd_to
      OPEN fwd_cur FOR iv_fwd_sql USING iv_loop_date
                                      , iv_loop_date
-- Ver1.3 M.Hokkanji End
                                      , gv_base
                                      , gv_cons_t_deliv
                                      , gv_cons_status
                                      , gv_wzero
                                      , gv_cons_notif_status
                                      , gv_cons_flg_yes
                                      , gv_flg_no
                                      , gv_cons_flg_yes
                                      , gv_cons_lot_ctl
                                      , gv_cons_item_product
                                      , gt_item_class
                                      , gv_cons_move_type
-- Ver1.3 M.Hokkanji Start
--                                      , gv_yyyymmdd_from
--                                      , gv_yyyymmdd_to
                                      , iv_loop_date
                                      , iv_loop_date
-- Ver1.3 M.Hokkanji End
                                      , gv_cons_mov_sts_c
                                      , gv_cons_mov_sts_e
                                      , gv_wzero
                                      , gv_cons_notif_status
                                      , gv_flg_no
                                      , gv_cons_flg_yes
                                      , gv_cons_lot_ctl
                                      , gv_cons_item_product
                                      , gt_item_class;
    END IF;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH fwd_cur BULK COLLECT INTO gr_demand_tbl;
--
    -- ���������̃Z�b�g
    gn_total_cnt := gr_demand_tbl.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE fwd_cur;
--
  EXCEPTION
-- Ver1.3 M.Hokkanji Start
-- �Ώۃf�[�^�����݂��Ȃ��ꍇ�͎擾����Ȃ��ꍇ�ł��������s�����邽��ret_code�ɈႤ�l��Ԃ��悤�ɕύX
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_req_nodata;
      CLOSE fwd_cur;  -- �J�[�\���N���[�Y
-- Ver1.3 M.Hokkanji End
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- �J�[�\���N���[�Y
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- �J�[�\���N���[�Y
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- �J�[�\���N���[�Y
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_demand_inf_fwd;
--
  /**********************************************************************************
  * Procedure Name   : release_lock
  * Description      : ���b�N����
  ***********************************************************************************/
  PROCEDURE release_lock(
    in_reqid              IN NUMBER,                     -- �v��ID
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'release_lock';       -- �v���O������
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
    lv_strsql VARCHAR2(1000);
    lv_phase  VARCHAR2(5);
    lv_staus  VARCHAR2(1);
--
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� START #####
    ln_reqid        NUMBER;           -- �v��ID
    ln_ret          BOOLEAN;
    lv_phase2       VARCHAR2(1000);
    lv_status2      VARCHAR2(1000);
    lv_dev_phase2   VARCHAR2(1000);
    lv_dev_status2  VARCHAR2(1000);
    lv_message2     VARCHAR2(1000);
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� END   #####
--
-- *----------* 2009/04/17 Ver.1.12 �{�ԏ�Q#1367�i1321�j���g���C�Ή� start *----------*
    ln_retrial_cnt  NUMBER;                 -- ���g���C��
    cn_seckill_cnt  CONSTANT NUMBER := 5;   -- ���g���C�ő��
-- *----------* 2009/04/17 Ver.1.12 �{�ԏ�Q#1367�i1321�j���g���C�Ή� end   *----------*
--
    -- *** ���[�J���E�J�[�\�� ***
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� START #####
--    CURSOR lock_cur
--    IS
--        SELECT
--            b.id1,
--            a.sid,
--            a.serial#,
--            b.type,
--            DECODE(b.lmode,1,'null', 2,'row share', 3,'row exclusive'
--             ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
--        FROM
--            v$session a,
--            v$lock b
--        WHERE
--            a.sid = b.sid
--            AND (b.id1, b.id2) in 
--                (SELECT d.id1, d.id2 FROM v$lock d 
--                 WHERE d.id1=b.id1
--                 AND d.id2=b.id2 AND d.request > 0) 
--            AND b.id1 IN (SELECT bb.id1
--                         FROM v$session aa, v$lock bb
--                         WHERE aa.lockwait = bb.kaddr 
--                         AND aa.module = 'XXWSH920008C')
--            AND b.lmode = 6;
--
-- ##### 20090218 Ver.1.9 �{��#1176�Ή� START #####
    -- gv$sesson�Agv$lock���Q�Ƃ���悤�ɏC��
--    CURSOR lock_cur
--      IS
--        SELECT b.id1, a.sid, a.serial#, b.type , a.inst_id , a.module , a.action
--              ,decode(b.lmode 
--                     ,1,'null' , 2,'row share', 3,'row exclusive' 
--                     ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
--        FROM gv$session a
--           , gv$lock    b
--        WHERE a.sid = b.sid
--        AND a.module <> 'XXWSH920008C'
--        AND (b.id1, b.id2) in (SELECT d.id1
--                                     ,d.id2
--                               FROM gv$lock d 
--                               WHERE d.id1     =b.id1 
--                               AND   d.id2     =b.id2 
--                               AND   d.request > 0) 
--        AND   b.id1 IN (SELECT bb.id1
--                      FROM   gv$session aa
--                            , gv$lock bb
--                      WHERE  aa.lockwait = bb.kaddr 
--                      AND    aa.module   = 'XXWSH920008C')
--        AND b.lmode = 6;
    -- RAC�\���Ή�SQL
    CURSOR lock_cur
      IS
        SELECT lok.id1            id1
             , lok_sess.inst_id   inst_id
             , lok_sess.sid       sid
             , lok_sess.serial#   serial#
             , lok.type           type
             , lok_sess.module    module
             , lok_sess.action    action
-- ##### 20090219 Ver.1.10 �{��#1176�Ή��i�ǉ��C���j START #####
             , lok.lmode          lmode
             , lok.request        request
             , lok.ctime          ctime
-- ##### 20090219 Ver.1.10 �{��#1176�Ή��i�ǉ��C���j END   #####
        FROM   gv$lock    lok
             , gv$session lok_sess
             , gv$lock    req
             , gv$session req_sess
        WHERE lok.inst_id = lok_sess.inst_id
          AND lok.sid     = lok_sess.sid
          AND lok.lmode   = 6
-- ##### 20090219 Ver.1.10 �{��#1176�Ή��i�ǉ��C���j START #####
          AND (lok.id1, lok.id2) IN (SELECT lok_not.id1, lok_not.id2
                                     FROM   gv$lock   lok_not
                                     WHERE  lok_not.id1 =lok.id1 
                                     AND    lok_not.id2 =lok.id2 
                                     AND    lok_not.request > 0) 
-- ##### 20090219 Ver.1.10 �{��#1176�Ή��i�ǉ��C���j END   #####
          AND req.inst_id = req_sess.inst_id
          AND req.sid     = req_sess.sid
          AND (   req.inst_id <> lok.inst_id
               OR req.sid     <> lok.sid)
          AND req.id1 = lok.id1
          AND req.id2 = lok.id2
-- 2016/05/11 D.Sugahara Ver1.16' Mod START
-- �^�p�e�X�g���W���[���Ƃ��āAXXWSH920008C_OT���Ăяo�����߁A���b�N�҂��m�F��_OT�ɕύX����B
---- *----------* 2009/05/01 Ver.1.13 �{�ԏ�Q#1367�i1321�j�q���O�Ή� start *----------*
--          -- �q�R���J�����g�̃��b�N�������O����
--          AND lok_sess.module <> 'XXWSH920008C'
---- *----------* 2009/05/01 Ver.1.13 �{�ԏ�Q#1367�i1321�j�q���O�Ή� end   *----------*
--          AND req_sess.module = 'XXWSH920008C'; 
---- *----------* 2009/05/01 Ver.1.13 �{�ԏ�Q#1367�i1321�j�q���O�Ή� start *----------*
          -- �q�R���J�����g�̃��b�N�������O����
          AND lok_sess.module <> 'XXWSH920008C_OT'
-- *----------* 2009/05/01 Ver.1.13 �{�ԏ�Q#1367�i1321�j�q���O�Ή� end   *----------*
          AND req_sess.module = 'XXWSH920008C_OT'; 
-- 2016/05/11 D.Sugahara Ver1.16' Mod End
--
-- ##### 20090218 Ver.1.9 �{��#1176�Ή� END   #####
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� END   #####
--
-- *----------* 2009/04/03 Ver.1.11 �{�ԏ�Q#1367�i1321�j�����p�Ή� start *----------*
    -- RAC�\���Ή�SQL�iSR�o�[�W�����j
    CURSOR lockSR_cur
      IS
        SELECT  ing.inst_id       ing_inst_id
              , ing.sid           ing_sid
              , ing.serial#       ing_serial
              , ing.username      ing_username
              , ing.event         ing_event
              , ing.module        ing_module
              , ing.action        ing_action
              , ed.inst_id        ed_inst_id
              , ed.sid            ed_sid
              , ed.serial#        ed_serial
              , ed.username       ed_username
              , ed.event          ed_event
              , ed.module         ed_module
              , ed.action         ed_action
              , ed_sql.sql_text   ed_sql_text
        FROM   gv$session ing       -- �u���b�N���Ă���Z�b�V����
             , gv$session ed        -- �u���b�N����Ă���Z�b�V����
             , gv$sqlarea ed_sql    -- ���b�N�҂����Ă���SQL
        WHERE ed.blocking_instance  = ing.inst_id
        AND   ed.blocking_session   = ing.sid
        AND   ed.inst_id            = ed_sql.inst_id(+)
        AND   ed.sql_address        = ed_sql.address(+)
-- 2016/05/11 D.Sugahara Ver1.16' Mod START
-- �^�p�e�X�g���W���[���Ƃ��āAXXWSH920008C_OT���Ăяo�����߁A���b�N�҂��m�F��_OT�ɕύX����B
--        AND   ed.module             = 'XXWSH920008C';
        AND   ed.module             = 'XXWSH920008C_OT';
-- 2016/05/11 D.Sugahara Ver1.16' Mod End
-- *----------* 2009/04/03 Ver.1.11 �{�ԏ�Q#1367�i1321�j�����p�Ή� end   *----------*
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- *----------* 2009/04/17 Ver.1.12 �{�ԏ�Q#1367�i1321�j���g���C�Ή� start *----------*
    -- �Z�b�V�����ؒf �m�F�񐔏�����
    ln_retrial_cnt  := 0;
-- *----------* 2009/04/17 Ver.1.12 �{�ԏ�Q#1367�i1321�j���g���C�Ή� end   *----------*
--
  LOOP
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� START #####
--        EXIT WHEN (lv_phase = 'Y' OR lv_staus = '1');
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� END   #####
        BEGIN
            SELECT DECODE(fcr.phase_code,'C','Y','I','Y','N')
            INTO   lv_phase
            FROM   fnd_concurrent_requests fcr 
            WHERE  fcr.request_id = in_reqid;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lv_phase := 'Y';
                NULL;
        END;
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� START #####
        EXIT WHEN (lv_phase = 'Y');
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� END   #####
        FOR lock_rec IN lock_cur LOOP
--
-- *----------* 2009/04/03 Ver.1.11 �{�ԏ�Q#1367�i1321�j�����p�Ή� start *----------*
          FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** ���b�N�҂��E���b�N�� �Z�b�V������� ********** ');
-- *----------* 2009/04/03 Ver.1.11 �{�ԏ�Q#1367�i1321�j�����p�Ή� end   *----------*
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� START #####
--          lv_strsql := 'ALTER SYSTEM KILL SESSION ''' || lock_rec.sid || ',' || lock_rec.serial# || ''' IMMEDIATE';
--          EXECUTE IMMEDIATE lv_strsql;
--          lv_staus := '1';
--
-- ##### 20090219 Ver.1.10 �{��#1176�Ή��i�ǉ��C���j START #####
          -- �폜�ΏۃZ�b�V�������O�o��
--          FND_FILE.PUT_LINE(FND_FILE.LOG, '�y�Z�b�V�����ؒf�z' || 
--                                          ' �����������F �v��ID[' || TO_CHAR(in_reqid) || '] ' ||
--                                          ' �ؒf�ΏۃZ�b�V�����F' ||
--                                          ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
--                                          ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
--                                          ' serial['  || TO_CHAR(lock_rec.serial#) || '] ' ||
--                                          ' action['  || lock_rec.action           || '] ' ||
--                                          ' module['  || lock_rec.module           || '] '
--                                          );
          FND_FILE.PUT_LINE(FND_FILE.LOG, '�y�Z�b�V�����ؒf�z' || ' �v��ID[' || TO_CHAR(in_reqid) || '] ' ||
                                          ' �ؒf�ΏۃZ�b�V�����F' ||
                                          ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
                                          ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
                                          ' serial#[' || TO_CHAR(lock_rec.serial#) || '] ' ||
                                          ' action['  || lock_rec.action           || '] ' ||
                                          ' module['  || lock_rec.module           || '] ' ||
                                          ' lmode['   || TO_CHAR(lock_rec.lmode)   || '] ' ||
                                          ' request[' || TO_CHAR(lock_rec.request) || '] ' ||
                                          ' ctime['   || TO_CHAR(lock_rec.ctime)   || '] '
                                          );
-- ##### 20090219 Ver.1.10 �{��#1176�Ή��i�ǉ��C���j END   #####
--
-- *----------* 2009/04/03 Ver.1.11 �{�ԏ�Q#1367�i1321�j�����p�Ή� start *----------*
          -- ���b�N�Z�b�V�����m�FSQL�iSR�o�[�W�����j�̃`�F�b�N
          FOR lockSR_rec IN lockSR_cur LOOP
--
            -- ���b�N���Ă���Z�b�V�����̏��o��
            FND_FILE.PUT_LINE(FND_FILE.LOG, '  �kSR�l���b�N�҂��v��ID [' || TO_CHAR(in_reqid) || '] ' ||
                                            '     Locked Session�F' ||
                                            ' inst_id[' || TO_CHAR(lockSR_rec.ing_inst_id) || '] ' ||
                                            ' sid['     || TO_CHAR(lockSR_rec.ing_sid)     || '] ' ||
                                            ' serial#[' || TO_CHAR(lockSR_rec.ing_serial)  || '] ' ||
                                            ' action['  || lockSR_rec.ing_action           || '] ' ||
                                            ' module['  || lockSR_rec.ing_module           || '] '
                                            );
--
            -- ���b�N�҂����Ă���SQL�o��
            FND_FILE.PUT_LINE(FND_FILE.LOG, '  �kSR�l Lock Waiting Session SQL <<<<<' || lockSR_rec.ed_sql_text || '>>>>>' );
          END LOOP;
-- *----------* 2009/04/03 Ver.1.11 �{�ԏ�Q#1367�i1321�j�����p�Ή� end   *----------*
--
-- *----------* 2009/04/17 Ver.1.12 �{�ԏ�Q#1367�i1321�j���g���C�Ή� start *----------*
          -- ���g���C�J�E���g UP
          ln_retrial_cnt := ln_retrial_cnt + 1;
--
          -- ���g���C�ő�񐔕��A���b�N�m�F������
          IF (ln_retrial_cnt <= cn_seckill_cnt) THEN
            -- ���b�N�҂����Ă���SQL�o��
            FND_FILE.PUT_LINE(FND_FILE.LOG, '   CONTINUE Retrial Count:' || TO_CHAR(ln_retrial_cnt) || ' Max Retrial Count:' || TO_CHAR(cn_seckill_cnt) );
            FND_FILE.PUT_LINE(FND_FILE.LOG, '');
--
            -- ����̃��b�N�m�F�܂ŁA5�b�҂�
            DBMS_LOCK.SLEEP(5);
            -- ���b�N�m�FSQL���ʂ���
            EXIT;
          END IF;
-- *----------* 2009/04/17 Ver.1.12 �{�ԏ�Q#1367�i1321�j���g���C�Ή� end   *----------*
--
          -- =====================================
          -- �Z�b�V�����ؒf�R���J�����g���N������
          -- =====================================
          ln_reqid := fnd_request.submit_request(
            Application => 'XXWSH',
            Program     => 'XXWSH000001C',
            Description => NULL,
            Start_Time  => SYSDATE,
            Sub_Request => FALSE,
            Argument1   => lock_rec.inst_id,
            Argument2   => lock_rec.sid    ,
            Argument3   => lock_rec.serial#
            );
          IF (ln_reqid > 0) THEN
            COMMIT;
          ELSE
            ROLLBACK;
            -- ���s�Ɏ��s�����ꍇ�̓G���[�ɂ����b�Z�[�W���o�͂���悤�ɏC��
            -- �G���[���b�Z�[�W�擾
            lv_errmsg  := SUBSTRB('XXWSH000001H �N���G���[ ' ||
                          ' inst_id[' || TO_CHAR(lock_rec.inst_id) || ']' ||
                          ' sid['     || TO_CHAR(lock_rec.sid)     || ']' ||
                          ' serial['  || TO_CHAR(lock_rec.serial#) || ']' || '<' || FND_MESSAGE.GET || '>'
                          ,1,5000);
            RAISE global_process_expt;
          END IF;
--
          -- ==============================================
          -- �N�������Z�b�V�����ؒf�R���J�����g�̏I����҂�
          -- ==============================================
          ln_ret := FND_CONCURRENT.WAIT_FOR_REQUEST(ln_reqid ,
                                                    0.05,
                                                    3600,
                                                    lv_phase2,
                                                    lv_status2,
                                                    lv_dev_phase2,
                                                    lv_dev_status2,
                                                    lv_message2);
          -- �X�e�[�^�X�m�F
          IF (ln_ret = FALSE) THEN
            -- �G���[�͖������āA���O�̂ݏo��
            lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                         ' �v��ID['  || TO_CHAR(ln_reqid) || ']' ||
                         ' phase['   || lv_dev_phase2     || ']' ||
                         ' status['  || lv_dev_status2    || ']' ||
                         ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                         , 1 ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
          -- COMPLETE�ȊO�ł̏I��
          ELSIF (lv_dev_phase2 <> 'COMPLETE') THEN
            -- �G���[�͖������āA���O�̂ݏo��
            lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                         ' �v��ID['  || TO_CHAR(ln_reqid) || ']' ||
                         ' phase['   || lv_dev_phase2     || ']' ||
                         ' status['  || lv_dev_status2    || ']' ||
                         ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                         , 1 ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
          -- �X�e�[�^�X��NORMAL�ȊO�ł̏I��
          ELSIF (lv_dev_status2 <> 'NORMAL') THEN
            -- �G���[�͖������āA���O�̂ݏo��
            lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                         ' �v��ID['  || TO_CHAR(ln_reqid) || ']' ||
                         ' phase['   || lv_dev_phase2     || ']' ||
                         ' status['  || lv_dev_status2    || ']' ||
                         ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                         , 1 ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
          END IF;
--
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� END   #####
--
-- *----------* 2009/04/17 Ver.1.12 �{�ԏ�Q#1367�i1321�j���g���C�Ή� start *----------*
          -- �Z�b�V�����ؒf��A���g���C�񐔂�������
          ln_retrial_cnt  := 0;
-- *----------* 2009/04/17 Ver.1.12 �{�ԏ�Q#1367�i1321�j���g���C�Ή� end   *----------*
--
-- *----------* 2009/04/03 Ver.1.11 �{�ԏ�Q#1367�i1321�j�����p�Ή� start *----------*
          -- �Z�b�V�����ؒf�ׁ̈A2�b�҂�
          DBMS_LOCK.SLEEP(2);
-- *----------* 2009/04/03 Ver.1.11 �{�ԏ�Q#1367�i1321�j�����p�Ή� end   *----------*
--
        END LOOP;
--
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� START #####
    -- �m�F��0.05�b�ҋ@����
    DBMS_LOCK.SLEEP(0.05);
-- ##### 20090119 Ver.1.04 �{��#1038�Ή� END   #####
--
  END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END release_lock;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_item_class         IN     VARCHAR2     -- ���i�敪
   , iv_action_type        IN     VARCHAR2     -- �������
   , iv_block1             IN     VARCHAR2     -- �u���b�N�P
   , iv_block2             IN     VARCHAR2     -- �u���b�N�Q
   , iv_block3             IN     VARCHAR2     -- �u���b�N�R
   , in_deliver_from_id    IN     NUMBER       -- �o�Ɍ�
   , in_deliver_type       IN     NUMBER       -- �o�Ɍ`��
   , iv_deliver_date_from  IN     VARCHAR2     -- �o�ɓ�From
   , iv_deliver_date_to    IN     VARCHAR2     -- �o�ɓ�To
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
   , iv_instruction_dept   IN     VARCHAR2     -- �w������
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start �{�ԏ�Q#1447�Ή�
   , iv_item_code          IN     VARCHAR2     -- �i�ڃR�[�h
-- 2009/05/19 H.Itou Add End
   , ov_errbuf             OUT  NOCOPY   VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode            OUT  NOCOPY   VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg             OUT  NOCOPY   VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_conc_p_c   CONSTANT VARCHAR2(100) := 'COMPLETE';
    cv_conc_s_w   CONSTANT VARCHAR2(100) := 'WARNING';
    cv_conc_s_e   CONSTANT VARCHAR2(100) := 'ERROR';
    cv_param_all  CONSTANT VARCHAR2(100) := 'ALL';
    cv_param_0    CONSTANT VARCHAR2(100) := '0';
    cv_param_1    CONSTANT VARCHAR2(100) := '1';
--
    -- *** ���[�J���ϐ� ***
    lc_out_param     VARCHAR2(1000);   -- ���̓p�����[�^�̏������ʃ��|�[�g�o�͗p
    lv_fwd_sql       VARCHAR2(5000);   -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql       VARCHAR2(5000);   -- �ړ��pSQL���i�[�o�b�t�@
--
    ln_d_cnt         NUMBER := 0;      -- ���v��񃋁[�v�J�E���^
    ln_s_cnt         NUMBER := 0;      -- ������񃋁[�v�J�E���^
    ln_k_cnt         NUMBER := 0;
    ln_s_max         NUMBER := 0;
    ln_i_cnt         NUMBER := 0;      -- ���v��񍇑̗p�J�E���^
--
    lv_phase         VARCHAR2(100);
    lv_status        VARCHAR2(100);
    lv_dev_phase     VARCHAR2(100);
    lv_dev_status    VARCHAR2(100);
    lv_lot_biz_class VARCHAR2(1);      -- ���b�g�t�]�������
    ln_result        NUMBER;           -- ��������(0:����A1:�ُ�)
    ld_standard_date DATE;             -- ����t
-- Ver1.3 M.Hokkanji Start
    ld_loop_date     DATE;             -- �����Ώۓ�
    ln_loop_cnt      NUMBER := 0;      -- ���[�v�J�E���g
-- Ver1.3 M.Hokkanji End
-- Ver1.15 M.Hokkanji Start
    lv_child_pgm         VARCHAR2(20);     --�qPGM�� ex)'XXWSH920008C'
-- 2016/05/11 D.Sugahara Ver1.16' Mod START
-- �^�p�e�X�g���W���[���Ƃ��āAXXWSH920008C_OT���Ăяo���悤�ɕύX����B
--    cv_child_pgm_origin  CONSTANT VARCHAR2(20) := 'XXWSH920008C';     --�qPGM�� ���������i�i�ځj�ʏ�
    cv_child_pgm_origin  CONSTANT VARCHAR2(20) := 'XXWSH920008C_OT';     --�qPGM�� ���������i�i�ځj_OT
-- 2016/05/11 D.Sugahara Ver1.16' Mod End
    cv_child_pgm_trace   CONSTANT VARCHAR2(20) := 'XXWSH920008C_2';   --�qPGM�� ���������i�i�ځjTrace�p
-- Ver1.15 M.Hokkanji End
    i                INTEGER := 0;
    TYPE reqid_tab IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    reqid_rec reqid_tab;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gt_item_class := iv_item_class;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- A-1  ���̓p�����[�^�`�F�b�N check_parameter
    -- ===============================================
    check_parameter(iv_item_class         -- ���̓p�����[�^���i�敪
                  , iv_deliver_date_from  -- ���̓p�����[�^�o�ɓ�From
                  , iv_deliver_date_to    -- ���̓p�����[�^�o�ɓ�To
                  , lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2  SQL�쐬
    -- ===============================================
    lv_fwd_sql := fwd_sql_create(iv_action_type     -- �������
                               , iv_block1          -- �u���b�N�P
                               , iv_block2          -- �u���b�N�Q
                               , iv_block3          -- �u���b�N�R
                               , in_deliver_from_id -- �o�Ɍ�
                               , in_deliver_type    -- �o�Ɍ`��
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
                               , iv_instruction_dept   -- �w������
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start �{�ԏ�Q#1447�Ή�
                               , iv_item_code       -- �i�ڃR�[�h
-- 2009/05/19 H.Itou Add End
                                 );
-- Ver1.3 M.Hokkanji Start
    ld_loop_date := TO_DATE(iv_deliver_date_from,'YYYY/MM/DD');
    gr_data_cnt_tbl.delete;
    ln_loop_cnt := 0;
    <<ship_date_loop>>
    LOOP
      -- ���t���Ƃɔz��ƑΏی�����������
      gr_demand_tbl.delete;
      gn_total_cnt := 0;
      ln_loop_cnt := ln_loop_cnt + 1;
      gr_data_cnt_tbl(ln_loop_cnt).ship_date := TO_CHAR(ld_loop_date,'YYYY/MM/DD');
      gr_data_cnt_tbl(ln_loop_cnt).error_cnt := 0;
      gr_data_cnt_tbl(ln_loop_cnt).warn_cnt  := 0;
      gr_data_cnt_tbl(ln_loop_cnt).nomal_cnt := 0;
      i := 0;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'****************�o�ח\����F' || TO_CHAR(ld_loop_date,'YYYY/MM/DD') || '*****************');
-- Ver1.3 M.Hokkanji End
      -- ===============================================
      -- A-3  �i�ڃR�[�h�擾
      -- ===============================================
      get_demand_inf_fwd(iv_action_type -- �������
-- Ver1.3 M.Hokkanji Start
                       , TO_CHAR(ld_loop_date,'YYYY/MM/DD')
-- Ver1.3 M.Hokkanji End
                       , lv_fwd_sql     -- SQL��
                       , lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[����
-- Ver1.3 M.Hokkanji Start
      IF ( lv_retcode = gv_req_nodata) THEN
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�o�ח\����F' || TO_CHAR(ld_loop_date,'YYYY/MM/DD') || '�����Ώۃf�[�^����');
        gn_total_cnt := 0;
      ELSIF ( lv_retcode = gv_status_error ) THEN
--      IF ( lv_retcode = gv_status_error ) THEN
-- Ver1.3 M.Hokkanji End
          gn_error_cnt := 1;
          RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- A-4  �i�ڃR�[�h���[�v
      -- ===============================================
      <<demand_inf_loop>>
      FOR ln_d_cnt IN 1..gn_total_cnt LOOP
        i := i + 1;
        gn_target_cnt := gn_target_cnt + 1;
-- Ver1.15 M.Hokkanji Start
--�g���[�X�擾�Ή� �i�ڂ�'0005000'�O�X�o���`���T�O�O�̏ꍇ��Trace�p�R���J�����g���Ăяo��
-- Ver1.16 M.Hokkanji Start
--        IF gr_demand_tbl(ln_d_cnt).item_code != '0005000' THEN
--          lv_child_pgm := cv_child_pgm_origin ; --09P500�ȊO�̏ꍇ�A�ʏ�
--        ELSE
--         lv_child_pgm := cv_child_pgm_trace  ; --Trace�p
--        END IF;
          lv_child_pgm := cv_child_pgm_origin ; --09P500�ȊO�̏ꍇ�A�ʏ�
-- Ver1.16 M.Hokkanji End
-- Ver1.15 M.Hokkanji End
        reqid_rec(i) := FND_REQUEST.SUBMIT_REQUEST(
                           application       => 'XXWSH'                           -- �A�v���P�[�V�����Z�k��
-- Ver1.15 M.Hokkanji Start
--                         , program           => 'XXWSH920008C'                    -- �v���O������
                         , program           => lv_child_pgm                    -- �v���O������
-- Ver1.15 M.Hokkanji End
                         , argument1         => iv_item_class                     -- ���i�敪
                         , argument2         => iv_action_type                    -- �������
                         , argument3         => iv_block1                         -- �u���b�N�P
                         , argument4         => iv_block2                         -- �u���b�N�Q
                         , argument5         => iv_block3                         -- �u���b�N�R
                         , argument6         => in_deliver_from_id                -- �o�Ɍ�
                         , argument7         => in_deliver_type                   -- �o�Ɍ`��
-- Ver1.3 M.hokkanji Start
                         , argument8         => TO_CHAR(ld_loop_date,'YYYY/MM/DD') -- �o�ɓ�From
                         , argument9         => TO_CHAR(ld_loop_date,'YYYY/MM/DD') -- �o�ɓ�To
--                         , argument8         => iv_deliver_date_from              -- �o�ɓ�From
--                         , argument9         => iv_deliver_date_to                -- �o�ɓ�To
-- Ver1.3 M.hokkanji End
                         , argument10        => gr_demand_tbl(ln_d_cnt).item_code -- �i�ڃR�[�h
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
                         , argument11        => iv_instruction_dept               -- �w������
-- 2009/01/28 H.Itou Add End
                           );
        -- �G���[�̏ꍇ
        IF ( reqid_rec(i) = 0 ) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application   => gv_cons_msg_kbn_cmn
                        ,iv_name          => gv_msg_xxcmn10135);
          RAISE global_api_others_expt;
        ELSE
          COMMIT;
        END IF;
-- Ver1.3 M.hokkanji Start
         -- �G���[����
--         IF ( lv_retcode = gv_status_error ) THEN
--             gn_error_cnt := 1;
--             RAISE global_process_expt;
--         END IF;
-- Ver1.3 M.hokkanji End
--
      END LOOP demand_inf_loop; -- �i�ڃR�[�h���[�v�I���
--
      -- ===============================================
      -- ���b�N�b��Ή�
      -- ===============================================
      <<lock_loop>>
      FOR k IN 1 .. i LOOP
              -- �q�v���ɂ��ă��b�N�Ŏ~�܂��Ă�����̂�i�߂�
              release_lock(reqid_rec(k)
                        , lv_errbuf
                        , lv_retcode
                        , lv_errmsg);
      END LOOP lock_loop; -- ���b�N�J�����[�v�I���
--
      -- ===============================================
      -- A-5  �R���J�����g�X�e�[�^�X�̃`�F�b�N
      -- ===============================================
      <<chk_status>>
      FOR j IN 1 .. i LOOP
        IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
               request_id => reqid_rec(j)
              ,interval   => 1
              ,max_wait   => 0
              ,phase      => lv_phase
              ,status     => lv_status
              ,dev_phase  => lv_dev_phase
              ,dev_status => lv_dev_status
              ,message    => lv_errbuf
              ) ) THEN
          -- �X�e�[�^�X���f
          -- �t�F�[�Y:����
          IF ( lv_dev_phase = cv_conc_p_c ) THEN
            -- �X�e�[�^�X:�ُ�
            IF ( lv_dev_status = cv_conc_s_e ) THEN
              ov_retcode := gv_status_error;
              FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�e�i��:' || gr_demand_tbl(j).item_code || '�A����:' || TO_CHAR(gr_demand_tbl(j).total_cnt) || '���A�v��ID�F' || TO_CHAR(reqid_rec(j)) || '�A�������ʁF' || gv_msg_part || gv_mst_error);
              gn_error_cnt := gn_error_cnt + 1;
-- Ver1.3 M.Hokkanji Start
              gr_data_cnt_tbl(ln_loop_cnt).error_cnt := gr_data_cnt_tbl(ln_loop_cnt).error_cnt + 1;
-- Ver1.3 M.Hokkanji End
            -- �X�e�[�^�X:�x��
            ELSIF ( lv_dev_status = cv_conc_s_w ) THEN
              IF ( ov_retcode < 1 ) THEN
                ov_retcode := gv_status_warn;
              END IF;
              FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�e�i��:' || gr_demand_tbl(j).item_code || '�A����:'  || TO_CHAR(gr_demand_tbl(j).total_cnt) || '���A�v��ID�F' || TO_CHAR(reqid_rec(j)) || '�A�������ʁF' || gv_msg_part || gv_mst_warn);
              gn_warn_cnt := gn_warn_cnt + 1;
-- Ver1.3 M.Hokkanji Start
              gr_data_cnt_tbl(ln_loop_cnt).warn_cnt := gr_data_cnt_tbl(ln_loop_cnt).warn_cnt + 1;
-- Ver1.3 M.Hokkanji End
            -- �X�e�[�^�X:����
            ELSE
              FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�e�i��:' || gr_demand_tbl(j).item_code || '�A����:'  || TO_CHAR(gr_demand_tbl(j).total_cnt) || '���A�v��ID�F' || TO_CHAR(reqid_rec(j)) || '�A�������ʁF' || gv_msg_part || gv_mst_normal);
              gn_normal_cnt := gn_normal_cnt + 1;
-- Ver1.3 M.Hokkanji Start
              gr_data_cnt_tbl(ln_loop_cnt).nomal_cnt := gr_data_cnt_tbl(ln_loop_cnt).nomal_cnt + 1;
-- Ver1.3 M.Hokkanji End
            END IF;
          END IF;
        ELSE
          ov_retcode := gv_status_error;
          FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j)) || gv_msg_part || gv_mst_error);
          gn_error_cnt := gn_error_cnt + 1;
        END IF;
--
      END LOOP chk_status;
-- Ver1.3 M.Hokkanji Start
      -- �G���[�����������ꍇ���̓��ŏI��
      IF (gn_error_cnt > 0) THEN
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�o�ɗ\���:' || TO_CHAR(ld_loop_date,'YYYY/MM/DD') || '�̈��������ŃG���[�������������ߏ����𒆒f���܂��B');
        EXIT;
      END IF;
      -- �����Ώۓ��t���o�ד�TO�ȏ�̏ꍇ���[�v�I��
      EXIT WHEN (ld_loop_date >= TO_DATE(iv_deliver_date_to,'YYYY/MM/DD'));
      -- ���[�v�I�����Ȃ��ꍇ�͏����Ώۓ��t+1
      ld_loop_date := ld_loop_date + 1;
    END LOOP ship_date_loop;
    -- ���t���Ƃ̏����o��
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'****************     ���t���Ƃ̏�������     *****************');
    <<msg_info_loop>>
    FOR m IN 1 .. gr_data_cnt_tbl.count LOOP
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�o�ɗ\���:' || gr_data_cnt_tbl(m).ship_date
                                      || '�A����  �����F' || TO_CHAR(gr_data_cnt_tbl(m).nomal_cnt)
                                      || '�A�x��  �����F' || TO_CHAR(gr_data_cnt_tbl(m).warn_cnt)
                                      || '�A�G���[�����F' || TO_CHAR(gr_data_cnt_tbl(m).error_cnt));
    END LOOP msg_info_loop;
-- Ver1.3 M.Hokkanji End
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf                OUT NOCOPY   VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT NOCOPY   VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_item_class         IN           VARCHAR2,      -- ���i�敪
    iv_action_type        IN           VARCHAR2,      -- �������
    iv_block1             IN           VARCHAR2,      -- �u���b�N�P
    iv_block2             IN           VARCHAR2,      -- �u���b�N�Q
    iv_block3             IN           VARCHAR2,      -- �u���b�N�R
    iv_deliver_from_id    IN           VARCHAR2,      -- �o�Ɍ�
    iv_deliver_type       IN           VARCHAR2,      -- �o�Ɍ`��
    iv_deliver_date_from  IN           VARCHAR2,      -- �o�ɓ�From
    iv_deliver_date_to    IN           VARCHAR2,      -- �o�ɓ�To
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
    iv_instruction_dept   IN           VARCHAR2       -- �w������
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start �{�ԏ�Q#1447�Ή�
   ,iv_item_code          IN           VARCHAR2       -- �i�ڃR�[�h
-- 2009/05/19 H.Itou Add End
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_deliver_from_id   NUMBER; -- �o�Ɍ�
    ln_deliver_type      NUMBER; -- �o�Ɍ`��
--
  BEGIN
--
    -- ���l�^�ɕϊ�����
    lv_retcode         := gv_cons_flg_yes;
    ln_deliver_from_id := TO_NUMBER(iv_deliver_from_id);
    lv_retcode         := gv_cons_flg_no;
    ln_deliver_type    := TO_NUMBER(iv_deliver_type);
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -----------------------------------------------
    -- ���̓p�����[�^�o��                        --
    -----------------------------------------------
    -- ���̓p�����[�^�u���i�敪�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02851', gv_tkn_item, iv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u������ʁv�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02852', 'AC_TYPE'  , iv_action_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N1�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02853', 'IN_BLOCK1', iv_block1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N2�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02854', 'IN_BLOCK2', iv_block2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N3�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02855', 'IN_BLOCK3', iv_block3);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�Ɍ��v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02856', 'FROM_ID'  , iv_deliver_from_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�Ɍ`�ԁv�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02857', 'TYPE'     , iv_deliver_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�ɓ�From�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02858', 'D_FROM'   , iv_deliver_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�ɓ�To�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02859', 'D_TO'     , iv_deliver_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
-- 2009/05/19 H.Itou Add Start �{�ԏ�Q#1447�Ή�
    -- ���̓p�����[�^�u�w�������v�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�w�������F'|| iv_instruction_dept);
    -- ���̓p�����[�^�u�i�ڃR�[�h�v�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�i�ڃR�[�h�F'|| iv_item_code);
-- 2009/05/19 H.Itou Add End
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    -- WHO�J�������̎擾
    gn_login_user       := FND_GLOBAL.LOGIN_ID;         -- ���O�C��ID
    gn_created_by       := FND_GLOBAL.USER_ID;          -- ���O�C�����[�UID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �R���J�����g�E�v���O����ID
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;   -- �Ώی���
    gn_normal_cnt := 0;   -- ���팏��
    gn_warn_cnt   := 0;   -- �x������
    gn_error_cnt  := 0;   -- �G���[����
--
    submain(
      iv_item_class,        -- ���i�敪
      iv_action_type,       -- �������
      iv_block1,            -- �u���b�N�P
      iv_block2,            -- �u���b�N�Q
      iv_block3,            -- �u���b�N�R
      ln_deliver_from_id,   -- �o�Ɍ�
      ln_deliver_type,      -- �o�Ɍ`��
      iv_deliver_date_from, -- �o�ɓ�From
      iv_deliver_date_to,   -- �o�ɓ�To
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
      iv_instruction_dept,  -- �w������
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start �{�ԏ�Q#1447�Ή�
      iv_item_code,         -- �i��
-- 2009/05/19 H.Itou Add End
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      IF ( lv_errmsg IS NULL ) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00008', 'CNT', TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00009', 'CNT', TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00010', 'CNT', TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    --gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00011', 'CNT', TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�x�������F ' || TO_CHAR(gn_warn_cnt) || ' ��');
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    WHEN INVALID_NUMBER THEN
      -- ���b�Z�[�W�̃Z�b�g
      -- �o�׌��ɕs���f�[�^����
      IF (lv_retcode = gv_cons_flg_yes) THEN
        lv_errbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_92a_009      -- �p�����[�^�����G���[
                                                      ,gv_tkn_parameter    -- �g�[�N��'PARAMETER'
                                                      ,gv_cons_deliv_fm    -- '�o�׌�'
                                                      ,gv_tkn_type         -- �g�[�N��'TYPE'
                                                      ,gv_cons_number)     -- '���l'
                                                      ,1
                                                      ,5000);
      -- �o�׌`�Ԃɕs���f�[�^����
      ELSE
        lv_errbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_92a_009      -- �p�����[�^�����G���[
                                                      ,gv_tkn_parameter    -- �g�[�N��'PARAMETER'
                                                      ,gv_cons_deliv_tp    -- '�o�׌`��'
                                                      ,gv_tkn_type         -- �g�[�N��'TYPE'
                                                      ,gv_cons_number)     -- '���l'
                                                      ,1
                                                      ,5000);
      END IF;
      errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      retcode := gv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXWSH920007C_OT;
/
