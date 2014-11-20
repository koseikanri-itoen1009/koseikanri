CREATE OR REPLACE PACKAGE xxwsh400004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400004c(spec)
 * Description      : �o�׈˗����ߊ֐�
 * MD.050           : �o�׈˗�               T_MD050_BPO_401
 * MD.070           : �o�׈˗����ߊ֐�       T_MD070_BPO_40E
 * Version          : 1.15
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  ship_tightening      �o�׈˗����ߊ֐�
 *
 *  Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/4/8      1.0   R.Matusita        ����쐬
 *  2008/5/19     1.1   Oracle �㌴���D �����ύX�v��#80�Ή� �p�����[�^�u���_�v�ǉ�
 *  2008/5/21     1.2   Oracle �㌴���D �����e�X�g�o�O�C��
 *                                      �p�����[�^�u���ߏ����敪�v��NULL�̂Ƃ���'1'(�������)�Ƃ���
 *                                      �w�������擾����SQL�C��(�ڋq���VIEW���Q�Ƃ��Ȃ�)
 *  2008/6/06     1.3   Oracle �Γn���a ���[�h�^�C���`�F�b�N���̔����ύX
 *  2008/6/27     1.4   Oracle �㌴���D �����ۑ�56�Ή� �ďo������ʂ̏ꍇ�ɂ����ߊǗ��A�h�I���o�^
 *  2008/6/30     1.5   Oracle �k�������v ST�s��Ή�#326
 *  2008/7/01     1.6   Oracle �k�������v ST�s��Ή�#338
 *  2008/08/05    1.7   Oracle �R����_ �o�גǉ�_5�Ή�
 *  2008/10/10    1.8   Oracle �ɓ��ЂƂ� �����e�X�g�w�E239�Ή�
 *  2008/10/28    1.9   Oracle �ɓ��ЂƂ� �����e�X�g�w�E141�Ή�
 *  2008/11/14   1.10  SCS    �ɓ��ЂƂ� �����e�X�g�w�E650�Ή�
 *  2008/12/01   1.11  SCS    �������   �{�Ԏw�E253�Ή��i�b��j 
 *  2008/12/07   1.12  SCS    �������   �{��#386
 *  2008/12/17   1.13  SCS    �㌴���D   �{��#81
 *  2008/12/17   1.13  SCS    ���c       APP-XXWSH-11204�G���[�������ɑ����I�����Ȃ��悤�ɂ���
 *  2008/12/23   1.14  SCS    �㌴       �{��#81 �Ē��ߏ������̒��o�����Ƀ��[�h�^�C����ǉ�
 *  2009/01/16   1.15  SCS    �������   �{��#1009 ���b�N�Z�b�V�����ؒf�Ή� 
 *****************************************************************************************/
--
  -- �o�׈˗����ߊ֐�
  PROCEDURE ship_tightening(
    in_order_type_id         IN  NUMBER    DEFAULT NULL, -- �o�Ɍ`��ID
    iv_deliver_from          IN  VARCHAR2  DEFAULT NULL, -- �o�׌�
    iv_sales_base            IN  VARCHAR2  DEFAULT NULL, -- ���_
    iv_sales_base_category   IN  VARCHAR2  DEFAULT NULL, -- ���_�J�e�S��
    in_lead_time_day         IN  NUMBER    DEFAULT NULL, -- ���Y����LT
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- �o�ɓ�
    iv_base_record_class     IN  VARCHAR2  DEFAULT NULL, -- ����R�[�h�敪
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- �˗�No
    iv_tighten_class         IN  VARCHAR2  DEFAULT NULL, -- ���ߏ����敪
    in_tightening_program_id IN  NUMBER    DEFAULT NULL, -- ���߃R���J�����gID
    iv_tightening_status_chk_class
                             IN  VARCHAR2,               -- ���߃X�e�[�^�X�`�F�b�N�敪
    iv_callfrom_flg          IN  VARCHAR2,               -- �ďo���t���O
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- ���i�敪
    iv_instruction_dept      IN  VARCHAR2  DEFAULT NULL, -- ����
    ov_errbuf                OUT NOCOPY  VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY  VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY  VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );    
END xxwsh400004c;
/
