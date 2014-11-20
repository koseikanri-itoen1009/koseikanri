/*============================================================================
* �t�@�C���� : XxcsoEmpSelSummaryVOImpl
* �T�v����   : �T�������󋵏Ɖ�^�����p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �S���ґI�����[�W�������������邽�߂̃r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpSelSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpSelSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param baseCd     �Ζ��拒�_�R�[�h
   *****************************************************************************
   */
  public void initQuery(
    String  baseCd 
  )
  {
    // ������
    setWhereClause(null);
    setWhereClauseParams(null);

    // �o�C���h�ւ̒l�̐ݒ�
    int idx = 0;
    setWhereClauseParam(idx++, baseCd);
    setWhereClauseParam(idx++, baseCd);
    setWhereClauseParam(idx++, baseCd);

    // SQL���s
    executeQuery();
  }

}