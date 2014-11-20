/*============================================================================
* �t�@�C���� : XxpoProvisionInstMakeTotalVOImpl
* �T�v����   : �x���w���쐬���v�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-14 1.0  ��r���     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * �x���w���쐬���v�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionInstMakeTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionInstMakeTotalVOImpl()
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