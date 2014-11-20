/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcFullVOImpl
* �T�v����   : �ꊇ�X�V���[�W�����r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS�x���a��    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �ꊇ�X�V���[�W�����̃r���[�N���X�ł��B
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param resourceNo          ���\�[�X�ԍ�
   * @param routeNo             ���[�gNo
   * @param baseCode            ���_�R�[�h
   *****************************************************************************
   */
  public void initQuery(
    String resourceNo
   ,String routeNo
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;

    setWhereClauseParam(index++, resourceNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, resourceNo);
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);

    executeQuery();
  }
}