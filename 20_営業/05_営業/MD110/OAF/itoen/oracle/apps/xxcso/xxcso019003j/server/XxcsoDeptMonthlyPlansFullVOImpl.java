/*============================================================================
* �t�@�C���� : XxcsoDeptMonthlyPlansFullVOImpl
* �T�v����   : ���_�ʌ��ʌv��e�[�u���o�^�^�X�V�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS�y���  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019003j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * ���_�ʌ��ʌv��e�[�u����o�^�^�X�V���邽�߂̃r���[�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDeptMonthlyPlansFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDeptMonthlyPlansFullVOImpl()
  {
  }
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param  baseCode�@���_�R�[�h
   *****************************************************************************
   */
  public void initQuery(
    String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, baseCode);

    executeQuery();

  }
}