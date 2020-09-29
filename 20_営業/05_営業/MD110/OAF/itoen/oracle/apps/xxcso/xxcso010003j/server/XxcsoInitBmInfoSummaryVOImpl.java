/*============================================================================
* �t�@�C���� : XxcsoInitBmInfoSummaryVOImpl
* �T�v����   : �����\����BM���擾�r���[�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����         �C�����e
* ---------- ---- -------------- ----------------------------------------------
* 2009-01-27 1.0  SCS����_      �V�K�쐬
* 2020-08-21 1.1  SCSK���X�ؑ�a [E_�{�ғ�_15904]�Ŕ������̋@�a�l�v�Z�ɂ���
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �����\����BM���擾�r���[�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInitBmInfoSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInitBmInfoSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param spDecisionHeaderId SP�ꌈ�w�b�_�[ID
   * @param bmClass            BM�̎�ށiBM1,BM2,BM3�j
   *****************************************************************************
   */
  public void initQuery(
    Number spDecisionCustomerId
// [E_�{�ғ�_15904] Add Start
   ,Number bmClass
// [E_�{�ғ�_15904] Add End
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);
    
// [E_�{�ғ�_15904] Mod Start
//    setWhereClauseParam(0, spDecisionCustomerId);
    setWhereClauseParam(0, bmClass);
    setWhereClauseParam(1, bmClass);
    setWhereClauseParam(2, spDecisionCustomerId);
// [E_�{�ғ�_15904] Add End

    executeQuery();
  }
}