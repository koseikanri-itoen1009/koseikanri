/*============================================================================
* �t�@�C���� : XxpoShipToTotalVOImpl
* �T�v����   : ���Ɏ��ѓ��͖��׍��v�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-01 1.0  �V���`��     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * ���Ɏ��ѓ��͖��׍��v�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �V�� �`��
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShipToTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShipToTotalVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   ****************************************************************************/
   public void initQuery(Number orderHeaderId)
  {
    // ������   
    setWhereClauseParams(null);
    setWhereClauseParam(0, orderHeaderId);
    // �������s
    executeQuery();

  }
}