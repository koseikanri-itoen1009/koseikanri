/*============================================================================
* �t�@�C���� : XxpoPoInquiryLineVOImpl
* �T�v����   : �����E����Ɖ���/����������׃r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-05-07 1.0  �ɓ��ЂƂ�   �V�K�쐬  �����ύX�v���Ή�(#41,48)
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Date;
/***************************************************************************
 * �����E����Ɖ���/����������׃r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxpoPoInquiryLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoInquiryLineVOImpl()
  {
  }
  
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchStatusCode     - �����X�e�[�^�X
   * @param searchDeliveryDate   - �[����
   * @param searchHeaderId       - �����w�b�_ID
   ****************************************************************************/
  public void initQuery( 
    String searchStatusCode,
    Date   searchDeliveryDate,
    String searchHeaderId
  )
  {
    // ������
    setWhereClauseParams(null);
          
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, searchStatusCode);
    setWhereClauseParam(1, searchStatusCode);
    setWhereClauseParam(2, searchStatusCode);
    setWhereClauseParam(3, searchStatusCode);
    setWhereClauseParam(4, searchDeliveryDate);
    setWhereClauseParam(5, searchDeliveryDate);
    setWhereClauseParam(6, searchDeliveryDate);
    setWhereClauseParam(7, searchDeliveryDate);
    setWhereClauseParam(8, searchDeliveryDate);
    setWhereClauseParam(9, searchDeliveryDate);
    setWhereClauseParam(10, searchHeaderId);
    
    // SELECT�����s
    executeQuery();
  }
}