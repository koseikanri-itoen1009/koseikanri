/*============================================================================
* t@C¼ : XxcsoRtnRsrcFullVOImpl
* Tvà¾   : êXV[Wr[NX
* o[W : 1.3
*============================================================================
* C³ð
* út       Ver. SÒ       C³àe
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCSxöaî  VKì¬
* 2009-06-24 1.1  SCSö½¼l  [áQ0000032]õ«\üPÎ
* 2010-03-23 1.2  SCS¢åã  [E_{Ò®_01942]Ç³_Î
* 2015-09-07 1.3  SCSKË¶aK [E_{Ò®_13307]|ÇÚqÎ
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * êXV[WÌr[NXÅ·B
 * @author  SCSxöaî
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
   * r[EIuWFNgÌú»ðs¢Ü·B
   * @param resourceNo          \[XÔ
   * @param routeNo             [gNo
   * @param baseCode            _R[h
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

// 2010-03-23 [E_{Ò®_01942] Add Start
    setWhereClauseParam(index++, baseCode);
// 2010-03-23 [E_{Ò®_01942] Add End
    setWhereClauseParam(index++, resourceNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
// 2009-06-24 [áQ0000032] Mod Start
//    setWhereClauseParam(index++, resourceNo);
//    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, resourceNo);
// 2009-06-24 [áQ0000032] Mod End
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
    setWhereClauseParam(index++, routeNo);
// 2015-09-07 [E_{Ò®_13307] Add Start
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, resourceNo);
    setWhereClauseParam(index++, routeNo);
// 2015-09-07 [E_{Ò®_13307] Add End

    executeQuery();
  }
}