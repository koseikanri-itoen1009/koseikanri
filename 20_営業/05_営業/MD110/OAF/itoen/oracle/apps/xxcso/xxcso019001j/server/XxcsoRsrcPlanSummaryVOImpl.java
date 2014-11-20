/*============================================================================
* �t�@�C���� : XxcsoRsrcPlanSummaryVOImpl
* �T�v����   : �K��E����v���ʁ@�c�ƈ��v���񃊁[�W�����r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �K��E����v���ʁ@�c�ƈ��v���񃊁[�W�����r���[�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRsrcPlanSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRsrcPlanSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param employeeNumber  �]�ƈ��ԍ�
   * @param fullName        �]�ƈ���
   * @param baseCode        ���_�R�[�h
   * @param planYearMonth   �v��N��
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
   ,String fullName
   ,String baseCode
   ,String yearMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;

    setWhereClauseParam(index++, employeeNumber);
    setWhereClauseParam(index++, fullName);
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, employeeNumber);
    setWhereClauseParam(index++, yearMonth);

    executeQuery();
  }
}