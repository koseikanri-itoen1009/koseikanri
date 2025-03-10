/*============================================================================
* t@C¼ : XxcsoRtnRsrcBulkUpdateEmployeeVOImpl
* Tvà¾   : _àScÆõr[NX
* o[W : 1.1
*============================================================================
* C³ð
* út       Ver. SÒ       C³àe
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCSxöaî    VKì¬
* 2010-03-23 1.1  SCS¢åã  [E_{Ò®_01942]Ç³_Î
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2010-03-23 [E_{Ò®_01942] Add Start
import oracle.jbo.domain.Date;
// 2010-03-23 [E_{Ò®_01942] Add End

/*******************************************************************************
 * _àScÆõÌr[NXÅ·B
 * @author  SCSxöaî
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateEmployeeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateEmployeeVOImpl()
  {
  }

  /*****************************************************************************
   * r[EIuWFNgÌú»ðs¢Ü·B
   * @param employeeNumber       ]ÆõÔ
   * @param baseCodeDate         ÎÛ_út
   * @param baseCode             _R[h
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
// 2010-03-23 [E_{Ò®_01942] Add Start
   ,Date   baseCodeDate
// 2010-03-23 [E_{Ò®_01942] Add End
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
// 2010-03-23 [E_{Ò®_01942] Add Start
    //setWhereClauseParam(1, baseCode);
    setWhereClauseParam(1, baseCodeDate);
// 2010-03-23 [E_{Ò®_01942] Add End
    setWhereClauseParam(2, baseCode);

    executeQuery();
  }
}